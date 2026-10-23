import dotenv from 'dotenv';
dotenv.config();

export const config = {
  port: parseInt(process.env.PORT || '3000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  databaseUrl: process.env.DATABASE_URL || 'postgres://onetour_user:onetour_secure_password_2026@localhost:5432/onetour_telemetry',
  pocketbaseUrl: process.env.POCKETBASE_URL || 'https://onetour-backend-onetour.gtalg3.easypanel.host'
};
