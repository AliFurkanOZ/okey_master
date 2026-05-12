require('dotenv').config();

// Veritabanını (Prisma) Taklit Et (Mock)
jest.mock('../src/utils/prisma', () => ({
  achievement: {
    findMany: jest.fn()
  },
  user: {
    findUnique: jest.fn()
  },
  userAchievement: {
    findMany: jest.fn(),
    create: jest.fn()
  },
  gamePlayer: {
    findFirst: jest.fn(),
    count: jest.fn()
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
const achievementRoutes = require('../src/routes/achievement.routes');
const prisma = require('../src/utils/prisma');

const app = express();
app.use(express.json());
app.use('/api/achievements', achievementRoutes);

describe('Achievement API Endpoints', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    it('GET /api/achievements should return all achievements', async () => {
        const fakeAchievements = [{ id: '1', name: 'İlk Oyun' }];
        prisma.achievement.findMany.mockResolvedValue(fakeAchievements);

        const response = await request(app).get('/api/achievements');
        expect(response.status).toBe(200);
        expect(response.body).toEqual(fakeAchievements);
    });

    it('GET /api/achievements/me should return user achievements', async () => {
        const fakeUserAchievements = [{ id: '1', achievement: { name: 'İlk Oyun' } }];
        prisma.user.findUnique.mockResolvedValue({ id: 'user-id', firebaseUid: 'test_firebase_uid' });
        prisma.userAchievement.findMany.mockResolvedValue(fakeUserAchievements);

        const response = await request(app).get('/api/achievements/me');
        expect(response.status).toBe(200);
        expect(response.body).toEqual(fakeUserAchievements);
    });

    it('POST /api/achievements/check should check and return new achievements', async () => {
        prisma.user.findUnique.mockResolvedValue({ 
            id: 'user-id', 
            stats: { totalWins: 10, winStreak: 5, totalGames: 20 } 
        });
        prisma.userAchievement.findMany.mockResolvedValue([]);
        prisma.achievement.findMany.mockResolvedValue([
            { id: 'ach1', conditionType: 'total_wins', conditionValue: 5 }
        ]);
        prisma.gamePlayer.findFirst.mockResolvedValue(null);
        prisma.gamePlayer.count.mockResolvedValue(0);
        prisma.userAchievement.create.mockResolvedValue({});

        const response = await request(app).post('/api/achievements/check').send({});
        expect(response.status).toBe(200);
        expect(response.body.newAchievements.length).toBe(1);
        expect(response.body.newAchievements[0].id).toBe('ach1');
    });
});
