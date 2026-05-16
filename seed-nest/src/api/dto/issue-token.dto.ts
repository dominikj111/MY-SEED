import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsOptional, IsString, MinLength } from 'class-validator';

export class IssueTokenDto {
  @ApiProperty({ example: 'admin@seed.local' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: 'password' })
  @IsString()
  @MinLength(1)
  password: string;

  @ApiProperty({ example: 'my-token', required: false })
  @IsOptional()
  @IsString()
  tokenName?: string;
}
