import { Injectable, Logger } from '@nestjs/common';
import * as nodemailer from 'nodemailer';

@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);
  private readonly transporter: nodemailer.Transporter;

  constructor() {
    this.transporter = nodemailer.createTransport({
      host: process.env.MAIL_HOST ?? 'mailpit',
      port: Number(process.env.MAIL_PORT ?? 1025),
      secure: false,
    });
  }

  async send(opts: { to: string; subject: string; text: string }) {
    await this.transporter.sendMail({
      from: process.env.MAIL_FROM_ADDRESS ?? 'hello@seed.local',
      ...opts,
    });
    this.logger.log(`Email sent to ${opts.to}: ${opts.subject}`);
  }
}
