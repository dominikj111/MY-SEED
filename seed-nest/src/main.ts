import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { ValidationPipe, Logger } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { WinstonModule } from 'nest-winston';
import * as winston from 'winston';
import * as session from 'express-session';
import * as passport from 'passport';
import { join } from 'path';
import { AppModule } from './app.module';

async function bootstrap() {
  const logger = WinstonModule.createLogger({
    transports: [
      new winston.transports.Console({
        format: winston.format.combine(
          winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
          winston.format.printf(({ timestamp, level, message, context }) =>
            `${timestamp} ${level.toUpperCase()} [${context ?? 'App'}] ${message}`,
          ),
        ),
      }),
      new winston.transports.File({
        filename: '/var/log/nest/app.log',
        format: winston.format.combine(
          winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
          winston.format.printf(({ timestamp, level, message, context }) =>
            `${timestamp} ${level.toUpperCase()} [${context ?? 'App'}] ${message}`,
          ),
        ),
      }),
    ],
  });

  const app = await NestFactory.create<NestExpressApplication>(AppModule, { logger });

  // ── Views (Handlebars) ──────────────────────────────────────────────────────
  app.setBaseViewsDir(join(__dirname, '..', 'views'));
  app.setViewEngine('hbs');

  // Register partials directory so {{> navbar}} works in templates
  const hbs = require('hbs');
  hbs.registerPartials(join(__dirname, '..', 'views', 'partials'));

  // ── Session + Passport ──────────────────────────────────────────────────────
  app.use(
    session({
      secret: process.env.PYTHON_SECRET_KEY ?? 'nest-dev-secret-change-in-prod',
      resave: false,
      saveUninitialized: false,
      cookie: { maxAge: 7_200_000 }, // 2 hours
    }),
  );
  app.use(passport.initialize());
  app.use(passport.session());

  // ── Global settings ─────────────────────────────────────────────────────────
  app.setGlobalPrefix('nest');
  app.useGlobalPipes(new ValidationPipe({ transform: true, whitelist: true }));

  // ── Swagger (OpenAPI) ────────────────────────────────────────────────────────
  const swaggerConfig = new DocumentBuilder()
    .setTitle('the-seed NestJS API')
    .setDescription('NestJS seed — public and Bearer-token protected endpoints.')
    .setVersion('1.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, swaggerConfig);
  // Mount docs at /nest/api/v1/docs (outside the global prefix so we control the path)
  SwaggerModule.setup('nest/api/v1/docs', app, document, {
    useGlobalPrefix: false,
  });

  await app.listen(3000, '0.0.0.0');
  new Logger('Bootstrap').log('NestJS running on http://0.0.0.0:3000/nest/');
}

bootstrap();
