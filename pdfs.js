import { supabase } from './supabase.js';
import { requireSchool } from './school.js';

const BUCKET = 'pdfs';

async function resolveSchoolId(schoolId) {
    if (schoolId) return schoolId;
    const school = await requireSchool();
    return school.id;
}

// Admin: upload a PDF for a school. `topicId` is optional — leave it null
// to attach the file to a subject label only. Pass schoolId to upload on
// behalf of another school (platform admin only — enforced by RLS).
export async function uploadPdf({ title, topicId = null, subject = '', file }, schoolId = null) {
    const sid = await resolveSchoolId(schoolId);

    if (!file) throw new Error('Please choose a PDF file.');
    if (file.type !== 'application/pdf') throw new Error('Only PDF files are allowed.');
    if (!title || !title.trim()) throw new Error('Please give the file a title.');

    const safeName = file.name.replace(/[^\w.\-]+/g, '_');
    const path = `${sid}/${Date.now()}_${safeName}`;

    const { error: uploadError } = await supabase.storage
        .from(BUCKET)
        .upload(path, file, { upsert: false, contentType: 'application/pdf' });

    if (uploadError) throw uploadError;

    const { data, error } = await supabase
        .from('pdf_resources')
        .insert({
            school_id: sid,
            topic_id: topicId,
            subject: subject || null,
            title: title.trim(),
            storage_path: path
        })
        .select()
        .single();

    if (error) throw error;
    return data;
}

export function pdfPublicUrl(storagePath) {
    const { data } = supabase.storage.from(BUCKET).getPublicUrl(storagePath);
    return data.publicUrl;
}

// Admin: list a school's own PDFs (dashboard). Pass schoolId to view
// another school's files (platform admin only — enforced by RLS).
export async function listMyPdfs(schoolId = null) {
    const sid = await resolveSchoolId(schoolId);
    return listPdfsForSchool(sid);
}

// Public: list a specific school's PDFs (no login needed — RLS allows public select).
export async function listPdfsForSchool(schoolId) {
    const { data, error } = await supabase
        .from('pdf_resources')
        .select('*')
        .eq('school_id', schoolId)
        .order('uploaded_at', { ascending: false });

    if (error) throw error;
    return data || [];
}

export async function deletePdf(id, storagePath, schoolId = null) {
    const sid = await resolveSchoolId(schoolId);

    await supabase.storage.from(BUCKET).remove([storagePath]);

    const { error } = await supabase
        .from('pdf_resources')
        .delete()
        .eq('id', id)
        .eq('school_id', sid);

    if (error) throw error;
    return true;
}

