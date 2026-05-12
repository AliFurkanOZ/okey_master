require('dotenv').config();

// Veritabanını (Prisma) Taklit Et (Mock)
jest.mock('../src/utils/prisma', () => ({
  $queryRaw: jest.fn()
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
const leaderboardRoutes = require('../src/routes/leaderboard.routes');
const prisma = require('../src/utils/prisma');

const app = express();
app.use(express.json());
app.use('/api/leaderboard', leaderboardRoutes);

describe('Leaderboard API Endpoints', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    it('GET /api/leaderboard/weekly should return leaderboard data', async () => {
        const fakeLeaderboard = [{ userId: 'user-id', username: 'TestUser', score: 100 }];
        prisma.$queryRaw.mockResolvedValue(fakeLeaderboard);

        const response = await request(app).get('/api/leaderboard/weekly');
        expect(response.status).toBe(200);
        expect(response.body).toEqual(fakeLeaderboard);
    });

    it('GET /api/leaderboard/invalid_period should return 400', async () => {
        const response = await request(app).get('/api/leaderboard/invalid_period');
        expect(response.status).toBe(400);
        expect(response.body).toHaveProperty('error', 'Geçersiz veri');
    });
});
