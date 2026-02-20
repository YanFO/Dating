import type {
  IcebreakerResponse,
  ReplyCoachResponse,
  LiveCoachHint,
  LiveCoachSessionSummary,
} from "@/types/api";

export function simulateDelay(ms: number = 1500): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export const MOCK_ICEBREAKER_RESPONSE: IcebreakerResponse = {
  scene_analysis: {
    location_type: "coffee_shop",
    observed_details: [
      "Reading a paperback novel",
      "Wearing a vintage band t-shirt (The Smiths)",
      "Iced oat latte on the table",
      "Sitting alone near the window",
    ],
    atmosphere: "Relaxed Sunday afternoon, lo-fi music playing",
    confidence: 0.87,
  },
  opening_lines: [
    {
      id: "ol-1",
      tone: "humorous",
      line: "I was going to ask what you're reading, but honestly I'm more curious about your oat latte order -- is it actually good or are we all just pretending?",
      explanation:
        "Self-deprecating humor about a shared experience (oat milk trend) breaks the ice without being too forward. It gives her an easy topic to respond to.",
      success_probability: 72,
    },
    {
      id: "ol-2",
      tone: "sincere",
      line: "Hey, I noticed your Smiths shirt -- are you into 80s post-punk or is that more of a vintage aesthetic thing? I'm genuinely curious.",
      explanation:
        "Shows genuine observation and interest. The qualifier 'genuinely curious' signals authenticity. Gives her room to share about music or fashion.",
      success_probability: 68,
    },
    {
      id: "ol-3",
      tone: "confident",
      line: "You look like you have great taste in books. Mind if I get a quick recommendation? I'm in a reading rut.",
      explanation:
        "Compliment + request for help creates a positive dynamic. People enjoy being asked for recommendations -- it validates their taste.",
      success_probability: 65,
    },
    {
      id: "ol-4",
      tone: "flirty",
      line: "I have to be honest -- I came here for the coffee, but you've completely distracted me from my work. What's the book?",
      explanation:
        "Direct but playful. Acknowledges attraction without being creepy because it pivots immediately to a genuine question about her activity.",
      success_probability: 58,
    },
  ],
  non_verbal_tips: [
    {
      id: "nv-1",
      category: "positioning",
      tip: "Approach from a slight angle, not head-on. Stand about 1.5 meters away initially. This feels less confrontational.",
      importance: "high",
    },
    {
      id: "nv-2",
      category: "body_language",
      tip: "Keep your hands visible and relaxed. Avoid crossing arms or putting hands in pockets.",
      importance: "high",
    },
    {
      id: "nv-3",
      category: "expression",
      tip: "Maintain a warm, genuine smile. Make brief eye contact before approaching to gauge openness.",
      importance: "high",
    },
    {
      id: "nv-4",
      category: "timing",
      tip: "Wait for a natural pause -- when she sets the book down or takes a sip. Don't interrupt mid-page.",
      importance: "medium",
    },
  ],
  overall_strategy:
    "This is a relaxed, low-pressure environment. She's alone and seems open to her surroundings (window seat, not wearing headphones). Use a genuine observation-based opener rather than a generic compliment. Keep it light, give her an easy out if she's not interested, and be ready to gracefully exit if she wants to get back to her book.",
};

export const MOCK_REPLY_COACH_RESPONSE: ReplyCoachResponse = {
  parsed_messages: [
    { id: "m1", sender: "user", text: "Hey! Had a great time last night 😊", timestamp: "2024-01-15T10:30:00Z" },
    { id: "m2", sender: "other", text: "Yeah it was fun", timestamp: "2024-01-15T14:22:00Z" },
    { id: "m3", sender: "user", text: "Want to grab dinner this weekend?", timestamp: "2024-01-15T14:25:00Z" },
    { id: "m4", sender: "other", text: "Hmm maybe, I'll have to check my schedule", timestamp: "2024-01-15T18:45:00Z" },
    { id: "m5", sender: "user", text: "Sure! Let me know 🙂", timestamp: "2024-01-15T18:47:00Z" },
    { id: "m6", sender: "other", text: "👍", timestamp: "2024-01-16T09:10:00Z" },
  ],
  sentiment: {
    overall_emotion: "cold",
    confidence: 0.78,
    subtext:
      "Her responses show declining engagement: shorter messages, longer delays (4h, then 4h again, then 14h for a thumbs-up). The pattern suggests fading interest rather than genuine busyness.",
    emoji_analysis:
      "Single thumbs-up emoji as a standalone response is a low-effort reply. Compare with your emoji usage (😊, 🙂) which shows more emotional investment.",
  },
  reply_options: [
    {
      id: "ro-1",
      tone: "confident",
      message: "No worries! I'm planning to check out that new ramen place on Saturday. You're welcome to join if you're free.",
      risk_level: "safe",
      expected_reaction:
        "Low pressure, shows you have your own plans. She can easily say yes without feeling cornered.",
    },
    {
      id: "ro-2",
      tone: "humorous",
      message: "I see your 👍 and raise you a 👍👍. But seriously, the place I have in mind has a 4.8 rating -- your call if you want to miss out 😄",
      risk_level: "moderate",
      expected_reaction:
        "Playful challenge that reframes the dynamic. Shows you're not anxious about her response.",
    },
    {
      id: "ro-3",
      tone: "sincere",
      message: "Hey, I want to be upfront -- I enjoy spending time with you and I'd like to see you again. But no pressure at all if you're not feeling it.",
      risk_level: "bold",
      expected_reaction:
        "Direct and vulnerable. Forces clarity. She'll either appreciate the honesty or confirm she's not interested -- either way, you get an answer.",
    },
  ],
  coach_analysis: {
    situation_summary:
      "The conversation shows a classic interest asymmetry. You are investing more emotional energy (longer messages, emojis, quick replies) while she is pulling back (short replies, long delays, minimal engagement).",
    detected_patterns: [
      "Reply delay increasing (30min -> 4h -> 14h)",
      "Message length decreasing (full sentence -> fragment -> emoji)",
      "No questions asked back to you",
      "Vague non-commitment ('maybe', 'I'll check')",
    ],
    recommended_strategy:
      "Pull back and mirror her energy level. Do not double-text or follow up asking if she's decided. Let her come to you. If she doesn't initiate within 3-4 days, the interest level is likely too low to pursue.",
    psychological_insight:
      "People who are genuinely interested make it easy to meet up. Vague responses like 'I'll check my schedule' without a counter-proposal are soft rejections. The key insight: her behavior is the message, not her words.",
    do_list: [
      "Match her response time (don't reply instantly)",
      "Keep your message short and confident",
      "Have your own plans regardless of her answer",
      "Give her space to miss your presence",
    ],
    dont_list: [
      "Don't send a follow-up asking if she's decided",
      "Don't increase your emoji usage to compensate",
      "Don't suggest alternative dates unprompted",
      "Don't express frustration or neediness",
    ],
  },
};

export const MOCK_LIVE_COACH_HINTS: LiveCoachHint[] = [
  {
    id: "lh-1",
    type: "topic_suggestion",
    content: "She mentioned traveling to Japan -- ask about her favorite neighborhood in Tokyo or if she prefers the countryside.",
    urgency: "medium",
    timestamp: Date.now(),
    expires_in_seconds: 30,
  },
  {
    id: "lh-2",
    type: "warning",
    content: "Conversation energy is dropping. You've been talking about work for 3 minutes -- pivot to something fun or personal.",
    urgency: "high",
    timestamp: Date.now(),
    expires_in_seconds: 15,
  },
  {
    id: "lh-3",
    type: "encouragement",
    content: "Great job! She laughed and is leaning in. Keep this energy going.",
    urgency: "low",
    timestamp: Date.now(),
    expires_in_seconds: 10,
  },
  {
    id: "lh-4",
    type: "question_prompt",
    content: "Try asking: 'What's something you're obsessed with right now that most people don't know about?'",
    urgency: "medium",
    timestamp: Date.now(),
    expires_in_seconds: 20,
  },
];

export const MOCK_SESSION_SUMMARY: LiveCoachSessionSummary = {
  duration_seconds: 420,
  total_hints_shown: 8,
  conversation_flow_score: 74,
  key_moments: [
    "Strong opening -- she responded positively to your humor",
    "Energy dipped around 3:00 mark during work topic",
    "Great recovery with the travel question",
    "Good closing -- left on a high note",
  ],
  improvement_tips: [
    "Avoid spending more than 2 minutes on any single topic",
    "Ask more open-ended questions instead of yes/no",
    "You spoke 60% of the time -- aim for 40-50%",
    "Your vocal energy drops when you're nervous -- try to maintain it",
  ],
};
