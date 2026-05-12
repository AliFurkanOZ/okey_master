// okey-master-server/test/auth.test.js
require('dotenv').config();

// Veritabanını (Prisma) Taklit Et (Mock)
jest.mock('../src/utils/prisma', () => ({
  user: {
    upsert: jest.fn(),
    findUnique: jest.fn(),
    delete: jest.fn()
  },
  $transaction: jest.fn(),
  gamePlayer: { updateMany: jest.fn() },
  game: { updateMany: jest.fn() },
  leaderboard: { deleteMany: jest.fn() },
  userAchievement: {
    findMany: jest.fn(),
    update: jest.fn(),
    delete: jest.fn()
  },
  userStats: { update: jest.fn() }
}));

// Firebase Admin'i Taklit Et (Mock)
jest.mock('firebase-admin', () => ({
  apps: [],
  initializeApp: jest.fn(),
  credential: { cert: jest.fn() }
}));

// Kimlik Doğrulama Middleware'ini Taklit Et (Mock)
jest.mock('../src/middleware/firebase-auth', () => ({
  verifyToken: (req, res, next) => {
    req.user = { uid: 'test_firebase_uid' }; 
    next();
  }
}));

const request = require('supertest');
const express = require('express');
const authRoutes = require('../src/routes/auth.routes');
const prisma = require('../src/utils/prisma');

const app = express();
app.use(express.json());
app.use('/api/auth', authRoutes);

describe('Auth API Tests', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('Kullanıcı adı 2 karakterden kısa ise 400 hatası dönmeli', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({ username: 'a' }); 
      
    expect(res.statusCode).toEqual(400);
    expect(res.body).toHaveProperty('error');
  });

  it('Geçerli kullanıcı adı ile register başarılı olmalı', async () => {
    const fakeUser = { id: 'u1', username: 'TestUser', stats: {} };
    prisma.user.upsert.mockResolvedValue(fakeUser);

    const res = await request(app)
      .post('/api/auth/register')
      .send({ username: 'TestUser' });

    expect(res.statusCode).toEqual(200);
    expect(res.body.username).toBe('TestUser');
    expect(prisma.user.upsert).toHaveBeenCalledTimes(1);
  });

  it('GET /profile 404 dönmeli eğer kullanıcı yoksa', async () => {
    prisma.user.findUnique.mockResolvedValue(null);

    const res = await request(app).get('/api/auth/profile');
    expect(res.statusCode).toEqual(404);
  });

  it('GET /profile kullanıcıyı stats ile dönmeli', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'u1', username: 'Test', stats: { totalGames: 5 } });

    const res = await request(app).get('/api/auth/profile');
    expect(res.statusCode).toEqual(200);
    expect(res.body.stats.totalGames).toBe(5);
  });

  it('POST /migrate geçerli değilse 400 dönmeli', async () => {
    const res = await request(app)
      .post('/api/auth/migrate')
      .send({ oldFirebaseUid: 'test_firebase_uid' }); // aynı uid

    expect(res.statusCode).toEqual(400);
  });

  it('POST /migrate başarılı işlem yapmalı', async () => {
    prisma.user.findUnique
      .mockResolvedValueOnce({ id: 'old1', stats: { totalGames: 5, avgScore: 10 } }) // old user
      .mockResolvedValueOnce({ id: 'new1', stats: { totalGames: 10, avgScore: 20 } }); // new user

    prisma.userAchievement.findMany.mockResolvedValue([]);

    prisma.$transaction.mockImplementation(async (callback) => {
      await callback(prisma);
    });

    const res = await request(app)
      .post('/api/auth/migrate')
      .send({ oldFirebaseUid: 'old_uid_123' });

    expect(res.statusCode).toEqual(200);
    expect(res.body.success).toBe(true);
    expect(prisma.user.delete).toHaveBeenCalled();
  });
});
