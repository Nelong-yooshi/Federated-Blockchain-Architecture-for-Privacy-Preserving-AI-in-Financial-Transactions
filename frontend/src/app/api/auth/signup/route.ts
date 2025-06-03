import { NextRequest, NextResponse } from 'next/server';
import fs from 'fs/promises';
import path from 'path';
import crypto from 'crypto';

export const runtime = 'nodejs';

type SignUpParams = {
  firstName: string;
  lastName: string;
  email: string;
  password: string;
};

const DATA_DIR = path.resolve(process.cwd(), 'data');
const USERS_FILE = path.join(DATA_DIR, 'users.json');

export async function POST(req: NextRequest) {
  try {
    const { firstName, lastName, email, password } = (await req.json()) as SignUpParams;
    await fs.mkdir(DATA_DIR, { recursive: true });

    const raw = await fs.readFile(USERS_FILE, 'utf-8').catch(() => '[]');
    const users: any[] = JSON.parse(raw);

    if (users.some(u => u.email === email)) {
      return NextResponse.json({ error: 'Email already registered' }, { status: 400 });
    }

    const token = crypto.randomUUID();
    const newUser = {
      id: `USR-${users.length.toString().padStart(3, '0')}`,
      firstName,
      lastName,
      email,
      password,
      token,
    };

    users.push(newUser);

    await fs.writeFile(USERS_FILE, JSON.stringify(users, null, 2));

    return NextResponse.json({ token });
  } catch (error) {
    console.error('❌ 註冊失敗:', error);
    return NextResponse.json({ error: 'Failed to register user' }, { status: 500 });
  }
}