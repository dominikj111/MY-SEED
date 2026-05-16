import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Logger,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';
import { TokenAuthGuard } from '../auth/guards/token-auth.guard';
import { User } from '../entities/user.entity';
import { ApiService } from './api.service';
import { IssueTokenDto } from './dto/issue-token.dto';

@ApiTags('public')
@Controller('api/v1')
export class PublicController {
  @ApiOperation({ summary: 'Service status — no auth required' })
  @Get('status')
  status() {
    return { status: 'ok', service: 'the-seed-nest', stack: 'NestJS + TypeORM' };
  }

  @ApiOperation({ summary: 'Liveness probe — no auth required' })
  @Get('ping')
  ping() {
    return { ping: 'pong' };
  }
}

@ApiTags('auth')
@Controller('api/v1')
export class AuthController {
  private readonly logger = new Logger(AuthController.name);

  constructor(private readonly api: ApiService) {}

  @ApiOperation({ summary: 'Issue a Bearer token' })
  @Post('auth/token')
  @HttpCode(201)
  async issueToken(@Body() dto: IssueTokenDto) {
    const token = await this.api.issueToken(
      dto.email,
      dto.password,
      dto.tokenName ?? 'api-token',
    );
    this.logger.log(`Token issued for ${dto.email}`);
    return {
      token: token.token,
      token_type: 'Bearer',
      user: { id: token.user.id, email: token.user.email },
    };
  }
}

@ApiTags('private')
@ApiBearerAuth()
@UseGuards(TokenAuthGuard)
@Controller('api/v1')
export class PrivateController {
  private readonly logger = new Logger(PrivateController.name);

  constructor(private readonly api: ApiService) {}

  @ApiOperation({ summary: 'Current user profile — Bearer token required' })
  @Get('me')
  me(@Req() req: Request) {
    const user = req.user as User;
    return {
      id: user.id,
      email: user.email,
      isAdmin: user.isAdmin,
      createdAt: user.createdAt,
    };
  }

  @ApiOperation({ summary: 'Revoke all tokens for the current user' })
  @Delete('token')
  @HttpCode(204)
  async revokeToken(@Req() req: Request) {
    const user = req.user as User;
    const count = await this.api.revokeAllTokens(user.id);
    this.logger.log(`Revoked ${count} token(s) for ${user.email}`);
  }
}
