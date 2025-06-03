import { NextRequest, NextResponse } from 'next/server';
import fs from 'fs/promises';
import path from 'path';

const USERS_FILE = path.resolve(process.cwd(), 'data/users.json');

export async function POST(req: NextRequest) {
  const body = await req.json();
  const { email, password } = body;

  const raw = await fs.readFile(USERS_FILE, 'utf-8').catch(() => '[]');
  const users = JSON.parse(raw);

  const user = users.find((u: any) => u.email === email && u.password === password);

  if (!user) {
    return NextResponse.json({ error: 'Invalid credentials' }, { status: 401 });
  }

  return NextResponse.json({ token: user.token });
}