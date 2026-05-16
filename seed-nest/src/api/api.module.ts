import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ApiToken } from '../entities/api-token.entity';
import { AuthModule } from '../auth/auth.module';
import { ApiService } from './api.service';
import { AuthController, PrivateController, PublicController } from './api.controller';

@Module({
  imports: [TypeOrmModule.forFeature([ApiToken]), AuthModule],
  providers: [ApiService],
  controllers: [PublicController, AuthController, PrivateController],
})
export class ApiModule {}
