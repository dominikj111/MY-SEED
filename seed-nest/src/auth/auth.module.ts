import { Module } from '@nestjs/common';
import { PassportModule } from '@nestjs/passport';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from '../entities/user.entity';
import { ApiToken } from '../entities/api-token.entity';
import { AuthService } from './auth.service';
import { LocalStrategy } from './local.strategy';
import { SessionSerializer } from './session.serializer';
import { TokenAuthGuard } from './guards/token-auth.guard';

@Module({
  imports: [
    PassportModule.register({ session: true }),
    TypeOrmModule.forFeature([User, ApiToken]),
  ],
  providers: [AuthService, LocalStrategy, SessionSerializer, TokenAuthGuard],
  exports: [AuthService, TokenAuthGuard],
})
export class AuthModule {}
