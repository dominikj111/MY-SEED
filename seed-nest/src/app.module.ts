import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from './entities/user.entity';
import { ApiToken } from './entities/api-token.entity';
import { AuthModule } from './auth/auth.module';
import { WebModule } from './web/web.module';
import { ApiModule } from './api/api.module';
import { MailModule } from './mail/mail.module';
import { SeedModule } from './seed/seed.module';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: process.env.DB_HOST ?? 'postgres',
      port: Number(process.env.DB_PORT ?? 5432),
      database: process.env.DB_DATABASE ?? 'seeddb',
      username: process.env.DB_USERNAME ?? 'seeduser',
      password: process.env.DB_PASSWORD ?? 'secret',
      entities: [User, ApiToken],
      // synchronize creates/updates tables automatically — fine for dev, not for prod
      synchronize: true,
    }),
    AuthModule,
    WebModule,
    ApiModule,
    MailModule,
    SeedModule,
  ],
})
export class AppModule {}
