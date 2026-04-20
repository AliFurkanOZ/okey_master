// okey-master-server/test/auth.test.js
require('dotenv').config();

// Veritabanını (Prisma) Taklit Et (Mock)
jest.mock('../src/utils/prisma', () => ({}));

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
// Prisma mock veya test DB ayarları eklenebilir.

const app = express();
app.use(express.json());
app.use('/api/auth', authRoutes);

describe('Auth API Tests', () => {
  it('Kullanıcı adı 2 karakterden kısa ise 400 hatası dönmeli', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({ username: 'a' }); // Geçersiz, çok kısa!
      
    expect(res.statusCode).toEqual(400);
    expect(res.body).toHaveProperty('error');
  });

  // Diğer testler (geçerli isim, profil getirme vs) buraya yazılacak.
});
