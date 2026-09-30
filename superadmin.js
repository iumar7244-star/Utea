import { supabase } from './supabase.js';
import { requireAuth } from './auth.js';

export async function isPlatformAdmin() {
    await requireAuth();
    const { data, error } = await supabase.rpc('is_platform_admin');
    if (error) throw error;
    return !!data;
}

export async function requirePlatformAdmin() {
    const ok = await isPlatformAdmin();
    if (!ok) throw new Error('This account does not have platform admin access.');
    return true;
}

export async function listAllSchools() {
    await requirePlatformAdmin();
    const { data, error } = await supabase.rpc('admin_list_schools');
    if (error) throw error;
    return data || [];
}

export async function listAllUsers() {
    await requirePlatformAdmin();
    const { data, error } = await supabase.rpc('admin_list_users');
    if (error) throw error;
    return data || [];
}

export async function deleteSchool(schoolId) {
    await requirePlatformAdmin();
    const { error } = await supabase.from('schools').delete().eq('id', schoolId);
    if (error) throw error;
    return true;
}
