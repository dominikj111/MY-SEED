import { Injectable } from '@nestjs/common';
import { PassportSerializer } from '@nestjs/passport';
import { AuthService } from './auth.service';
import { User } from '../entities/user.entity';

@Injectable()
export class SessionSerializer extends PassportSerializer {
  constructor(private readonly auth: AuthService) {
    super();
  }

  serializeUser(user: User, done: (err: any, id: number) => void) {
    done(null, user.id);
  }

  async deserializeUser(id: number, done: (err: any, user: User | null) => void) {
    const user = await this.auth.findById(id);
    done(null, user ?? null);
  }
}
