import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from '../entities/user.entity';
import { ApiToken } from '../entities/api-token.entity';
import { AuthModule } from '../auth/auth.module';
import { MailModule } from '../mail/mail.module';
import { WebController } from './web.controller';
import { WebService } from './web.service';

@Module({
  imports: [TypeOrmModule.forFeature([User, ApiToken]), AuthModule, MailModule],
  controllers: [WebController],
  providers: [WebService],
})
export class WebModule {}
