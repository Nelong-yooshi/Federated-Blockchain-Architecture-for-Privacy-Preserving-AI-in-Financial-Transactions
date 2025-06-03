import { NextRequest, NextResponse } from 'next/server';
import fs from 'fs/promises';
import path from 'path';

const USERS_FILE = path.resolve(process.cwd(), 'data/users.json');

export async function POST(req: NextRequest) {
  const { email } = await req.json();

  const raw = await fs.readFile(USERS_FILE, 'utf-8').catch(() => '[]');
  const users = JSON.parse(raw);

  const user = users.find((u: any) => u.email === email);
  if (!user) {
    return NextResponse.json({ error: 'User not found' }, { status: 404 });
  }

  user.password = 'reset123'; // 假設預設新密碼（你可以做 email 寄送）

  await fs.writeFile(USERS_FILE, JSON.stringify(users, null, 2));

  return NextResponse.json({ message: 'Password reset to "reset123"' });
}