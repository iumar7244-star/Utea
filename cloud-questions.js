import { supabase } from './supabase.js';
import { requireSchool } from './school.js';

// If a schoolId is passed (platform admin managing another school), use it.
// Otherwise fall back to the logged-in user's own school. Row Level Security
// in the database still decides whether the caller is actually allowed.
async function resolveSchoolId(schoolId) {
    if (schoolId) return schoolId;
    const school = await requireSchool();
    return school.id;
}

// ------------------------------------------------------------
// TOPICS
// ------------------------------------------------------------

export async function addTopic({ termId, code, subject }, schoolId = null) {
    const sid = await resolveSchoolId(schoolId);

    if (!subject || !subject.trim()) throw new Error('Topic name is required.');
    if (!termId) throw new Error('Please choose a term.');

    const { data: topic, error: topicError } = await supabase
        .from('topics')
        .insert({
            school_id: sid,
            code: (code || '').trim() || null,
            subject: subject.trim()
        })
        .select()
        .single();

    if (topicError) throw topicError;

    const { error: linkError } = await supabase
        .from('term_topics')
        .insert({ school_id: sid, term_id: termId, topic_id: topic.id });

    if (linkError) throw linkError;
    return topic;
}

export async function getSchoolTopics(schoolId = null) {
    const sid = await resolveSchoolId(schoolId);

    const { data, error } = await supabase
        .from('topics')
        .select('*')
        .eq('school_id', sid)
        .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
}

export async function deleteTopic(topicId, schoolId = null) {
    const sid = await resolveSchoolId(schoolId);

    await supabase.from('questions').delete().eq('topic_id', topicId).eq('school_id', sid);
    await supabase.from('term_topics').delete().eq('topic_id', topicId).eq('school_id', sid);

    const { error } = await supabase
        .from('topics')
        .delete()
        .eq('id', topicId)
        .eq('school_id', sid);

    if (error) throw error;
    return true;
}

// ------------------------------------------------------------
// QUESTIONS
// ------------------------------------------------------------

export async function getQuestions(topicId, schoolId = null) {
    const sid = await resolveSchoolId(schoolId);

    const { data, error } = await supabase
        .from('questions')
        .select('*')
        .eq('school_id', sid)
        .eq('topic_id', topicId)
        .order('created_at', { ascending: true });

    if (error) throw error;
    return data || [];
}

export async function addQuestion({ topicId, topicCode, question, answer, acceptable }, schoolId = null) {
    const sid = await resolveSchoolId(schoolId);

    if (!question || !question.trim() || !answer || !answer.trim()) {
        throw new Error('Question and answer are both required.');
    }

    const { data, error } = await supabase
        .from('questions')
        .insert({
            school_id: sid,
            topic_id: topicId,
            topic_code: topicCode || null,
            question: question.trim(),
            type: 'typing',
            answer: answer.trim(),
            acceptable: acceptable && acceptable.length ? acceptable : [],
            marks: 1,
            difficulty: 'medium',
            active: true
        })
        .select()
        .single();

    if (error) throw error;
    return data;
}

export async function deleteQuestion(questionId, schoolId = null) {
    const sid = await resolveSchoolId(schoolId);

    const { error } = await supabase
        .from('questions')
        .delete()
        .eq('id', questionId)
        .eq('school_id', sid);

    if (error) throw error;
    return true;
}
