import { NextResponse } from 'next/server'
import fs from 'fs'
import path from 'path'
import got from 'got'

export const runtime = 'nodejs'

export async function POST() {
  try {
    const url = 'https://gwcs.nemo00407.uk/'
    const response = await got(url).json<Record<string, string>>()

    const categories = Object.keys(response).join(',')
    const times = Object.values(response).join(',')

    const envPath = path.resolve('.env.local')

    let env = ''
    if (fs.existsSync(envPath)) {
      env = fs.readFileSync(envPath, 'utf-8')
    }

    const lines = env.split('\n').filter(Boolean)
    const envMap: Record<string, string> = {}
    for (const line of lines) {
      const [key, ...rest] = line.split('=')
      envMap[key] = rest.join('=')
    }

    envMap['NEXT_PUBLIC_CATEGORIES'] = categories
    envMap['NEXT_PUBLIC_TIMES'] = times

    const newEnvString = Object.entries(envMap)
      .map(([key, val]) => `${key}=${val}`)
      .join('\n')

    fs.writeFileSync(envPath, newEnvString)

    return NextResponse.json({
      message: '✅ .env.local 已更新',
      categories,
      times,
    })
  } catch (error: any) {
    console.error(error)
    return NextResponse.json(
      { error: '❌ 更新失敗', detail: error.message },
      { status: 500 }
    )
  }
}

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url)
    const url = searchParams.get('url') || 'https://default-url-if-empty'
    
    const response = await fetch(url)
    const status = response.status

    return NextResponse.json({
      message: '✅ 外部 GET 已發送',
      forwardUrl: url,
      statusCode: status,
    })
  } catch (error: any) {
    console.error(error)
    return NextResponse.json(
      { error: '❌ 外部 GET 發送失敗', detail: error.message },
      { status: 501 }
    )
  }
}