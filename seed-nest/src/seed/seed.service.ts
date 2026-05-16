import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { randomBytes } from 'crypto';
import * as bcrypt from 'bcrypt';
import { User } from '../entities/user.entity';
import { ApiToken } from '../entities/api-token.entity';

@Injectable()
export class SeedService implements OnModuleInit {
  private readonly logger = new Logger(SeedService.name);

  constructor(
    @InjectRepository(User) private readonly users: Repository<User>,
    @InjectRepository(ApiToken) private readonly tokens: Repository<ApiToken>,
  ) {}

  async onModuleInit() {
    const email = process.env.DEMO_USER_EMAIL ?? 'admin@seed.local';
    const password = process.env.DEMO_USER_PASSWORD ?? 'password';

    let user = await this.users.findOneBy({ email });
    if (!user) {
      user = this.users.create({
        email,
        password: await bcrypt.hash(password, 10),
        isAdmin: true,
      });
      await this.users.save(user);
      this.logger.log(`[nest] Demo user created: ${email}`);
    } else {
      this.logger.log(`[nest] Demo user already exists: ${email}`);
    }

    const existing = await this.tokens.findOneBy({ name: 'Demo Token', user: { id: user.id } });
    if (!existing) {
      const token = this.tokens.create({
        token: randomBytes(32).toString('hex'),
        name: 'Demo Token',
        user,
      });
      await this.tokens.save(token);
      this.logger.log(`[nest] Demo API token: ${token.token}`);
    } else {
      this.logger.log(`[nest] Demo API token (existing): ${existing.token}`);
    }

    this.logger.log(`[nest] Login: ${email} / ${password}`);
  }
}
