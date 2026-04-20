const { PrismaClient } = require('@prisma/client');
const { Pool } = require('pg');
const { PrismaPg } = require('@prisma/adapter-pg');

// Veritabanı bağlantı havuzunu (pool) oluşturuyoruz
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

// Prisma 7 için resmi PostgreSQL adaptörünü oluşturuyoruz
const adapter = new PrismaPg(pool);

const prisma = new PrismaClient({
  adapter, // Adaptörü Prisma'ya veriyoruz
  log: process.env.NODE_ENV === 'development'
    ? ['query', 'warn', 'error']
    : ['warn', 'error'],
});

module.exports = prisma;
