import { NextRequest, NextResponse } from 'next/server';
import fs from 'fs/promises';
import path from 'path';

const USERS_FILE = path.resolve(process.cwd(), 'data/users.json');

export async function GET(req: NextRequest) {
  try {
    const authHeader = req.headers.get('authorization');
    const token = authHeader?.split(' ')[1] || '';

    const raw = await fs.readFile(USERS_FILE, 'utf-8');
    const users = JSON.parse(raw);

    const user = users.find((u: any) => u.token === token);
    if (!user) {
      // 找不到 user，不回傳錯誤，status 仍為 200
      return NextResponse.json(null, { status: 200 });
    }

    return NextResponse.json({
      id: user.id,
      avatar: '/assets/avatar.png',
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email,
    });
  } catch (err: any) {
    console.error('[GET /api/auth/me] Error:', err);
    return NextResponse.json({ error: 'Server error' }, { status: 500 });
  }
}
