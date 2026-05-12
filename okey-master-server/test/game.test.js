require('dotenv').config();
const crypto = require('crypto');

// Veritabanını (Prisma) Taklit Et (Mock)
jest.mock('../src/utils/prisma', () => ({
  user: { findUnique: jest.fn() },
  game: {
    updateMany: jest.fn(),
    count: jest.fn(),
    create: jest.fn(),
    findUnique: jest.fn(),
    update: jest.fn()
  },
  idempotencyKeys: {
    findUnique: jest.fn(),
    create: jest.fn()
  },
  gamePlayer: {
    updateMany: jest.fn(),
    findMany: jest.fn()
  },
  userStats: {
    upsert: jest.fn(),
    update: jest.fn()
  },
  $transaction: jest.fn()
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
const gameRoutes = require('../src/routes/game.routes');
const prisma = require('../src/utils/prisma');

const app = express();
app.use(express.json());
app.use('/api/games', gameRoutes);

describe('Game API Endpoints', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    it('POST /api/games should require valid mode', async () => {
        const response = await request(app).post('/api/games').send({ mode: 'invalid_mode' });
        expect(response.status).toBe(400);
    });

    it('POST /api/games/:id/finish should fail for invalid UUID', async () => {
        const response = await request(app).post('/api/games/invalid-uuid/finish').send({});
        expect(response.status).toBe(400);
    });

    it('POST /api/games createGame succeeds', async () => {
        prisma.user.findUnique.mockResolvedValue({ id: 'u1', firebaseUid: 'test_firebase_uid' });
        prisma.game.updateMany.mockResolvedValue({});
        prisma.game.count.mockResolvedValue(0);
        prisma.game.create.mockResolvedValue({ id: 'g1', mode: 'offline_easy', serverSeed: 'abcd' });

        const response = await request(app).post('/api/games').send({ mode: 'offline_easy' });
        expect(response.status).toBe(200);
        expect(response.body.id).toBe('g1');
        expect(response.body.serverSeed).toBeUndefined();
        expect(response.body.seedCommitment).toBeDefined();
    });

    it('POST /api/games/:id/finish checks active duration and hash', async () => {
        const gameId = 'a1b2c3d4-e5f6-7a8b-9c0d-e1f2a3b4c5d6';
        const moveLog = 'move1,move2';
        const totalTurns = 5;
        const playerScore = 50;
        const serverSeed = 'secretseed';

        // Expected hash
        const expectedHash = crypto.createHash('sha256')
            .update(`${serverSeed}:${moveLog}:turns=${totalTurns}:score=${playerScore}`)
            .digest('hex');

        prisma.idempotencyKeys.findUnique.mockResolvedValue(null);
        prisma.game.findUnique.mockResolvedValue({
            id: gameId,
            status: 'playing',
            startedAt: new Date(Date.now() - 60000), // 60 seconds ago, valid
            serverSeed: serverSeed,
            mode: 'offline_easy',
            players: [{ userId: 'u1' }]
        });
        prisma.user.findUnique.mockResolvedValue({ id: 'u1' });
        prisma.game.count.mockResolvedValue(0); // Frequency limit pass
        
        prisma.$transaction.mockImplementation(async (callback) => {
            return await callback(prisma);
        });
        prisma.game.update.mockResolvedValue({ id: gameId, status: 'finished' });
        prisma.userStats.upsert.mockResolvedValue({ winStreak: 2, bestWinStreak: 5, totalGames: 10, avgScore: 10 });

        const response = await request(app).post(`/api/games/${gameId}/finish`).send({
            winnerId: 'u1',
            players: [{ userId: 'u1', score: playerScore, isWinner: true }],
            totalTurns: totalTurns,
            gameHash: expectedHash,
            moveLog: moveLog
        });

        expect(response.status).toBe(200);
        expect(response.body.status).toBe('finished');
        expect(prisma.$transaction).toHaveBeenCalled();
    });
});

