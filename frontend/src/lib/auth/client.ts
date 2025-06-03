'use client';

import type { User } from '@/types/user';

const user = null;

export interface SignUpParams {
  firstName: string;
  lastName: string;
  email: string;
  password: string;
}

// export interface SignInWithOAuthParams {
//   provider: 'google' | 'discord';
// }

export interface SignInWithPasswordParams {
  email: string;
  password: string;
}

export interface ResetPasswordParams {
  email: string;
}

class AuthClient {
  
  async signUp(params: SignUpParams): Promise<{ error?: string }> {
    try {
      const res = await fetch('/api/auth/signup', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(params),
      });

      const data = await res.json();
      if (!res.ok) return { error: data.error };

      localStorage.setItem('custom-auth-token', data.token);
      
      return {};
    } catch {
      return { error: 'Server error' };
    }
  }

  // async signInWithOAuth(_: SignInWithOAuthParams): Promise<{ error?: string }> {
  //   return { error: 'Social authentication not implemented' };
  // }

  async signInWithPassword(params: SignInWithPasswordParams): Promise<{ error?: string }> {
    try {
      const res = await fetch('/api/auth/signin', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(params),
      });

      const data = await res.json();

      if (!res.ok) {
        return { error: data.error || 'Login failed' };
      }

      localStorage.setItem('custom-auth-token', data.token);
      return {};
    } catch (error) {
      return { error: 'Server error' };
    }
  }

  async resetPassword(params: ResetPasswordParams): Promise<{ error?: string }> {
    try {
      const res = await fetch('/api/auth/reset', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(params),
      });

      const data = await res.json();
      if (!res.ok) return { error: data.error };

      return {};
    } catch {
      return { error: 'Server error' };
    }
  }

  async updatePassword(params: { email: string; password: string }): Promise<{ error?: string }> {
    try {
      const res = await fetch('/api/auth/update-password', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(params),
      });

      const data = await res.json();
      if (!res.ok) return { error: data.error };

      return {};
    } catch {
      return { error: 'Server error' };
    }
  }

 async getUser(): Promise<{ data?: User | null; error?: string }> {
    const token = localStorage.getItem('custom-auth-token');

    if (!token) {
      return { data: null };
    }

    try {
      const res = await fetch('/api/auth/me', {
        method: 'GET',
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      const data = await res.json();
      if (!res.ok) {
        return { data: null, error: data.error || 'Unauthorized' };
      }

      return { data };
    } catch {
      return { data: null, error: 'Server error' };
    }
  }


  async signOut(): Promise<{ error?: string }> {
    localStorage.removeItem('custom-auth-token');
    return {};
  }
}

export const authClient = new AuthClient();
