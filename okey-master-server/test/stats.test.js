require('dotenv').config();

// Veritabanını (Prisma) Taklit Et (Mock)
jest.mock('../src/utils/prisma', () => ({
  user: {
    findUnique: jest.fn()
  },
  userStats: {
    findUnique: jest.fn()
  }
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
const statsRoutes = require('../src/routes/stats.routes');
const prisma = require('../src/utils/prisma');

const app = express();
app.use(express.json());
app.use('/api/stats', statsRoutes);

describe('Stats API Endpoints', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    it('GET /api/stats/me should return 404 if stats not found', async () => {
        prisma.user.findUnique.mockResolvedValue({ id: 'user-id', firebaseUid: 'test_firebase_uid' });
        prisma.userStats.findUnique.mockResolvedValue(null);

        const response = await request(app).get('/api/stats/me');
        expect(response.status).toBe(404);
        expect(response.body).toHaveProperty('error', 'İstatistik bulunamadı.');
    });

    it('GET /api/stats/me should return stats', async () => {
        const fakeStats = { totalGames: 10, totalWins: 5, avgScore: 12.5 };
        prisma.user.findUnique.mockResolvedValue({ id: 'user-id', firebaseUid: 'test_firebase_uid' });
        prisma.userStats.findUnique.mockResolvedValue(fakeStats);

        const response = await request(app).get('/api/stats/me');
        expect(response.status).toBe(200);
        expect(response.body).toEqual(fakeStats);
    });

    it('GET /api/stats/:userId should return stats for specific user', async () => {
        const fakeStats = { totalGames: 20, user: { username: 'TestUser' } };
        prisma.userStats.findUnique.mockResolvedValue(fakeStats);

        const response = await request(app).get('/api/stats/some-user-id');
        expect(response.status).toBe(200);
        expect(response.body.user.username).toBe('TestUser');
    });
});
