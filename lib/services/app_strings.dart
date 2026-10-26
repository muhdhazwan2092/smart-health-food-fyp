import 'language_state.dart';

/// Translations for the app's own text (buttons, titles, labels, messages).
///
/// Use it like this:   Text(tr('dash_welcome'))
/// With values:        tr('percent_of_goal', {'p': '75'})   // "{p}%" is replaced
///
/// To translate a new screen: add keys here, then replace the typed English
/// text in that screen with tr('key'). If a key has no Malay or Chinese text
/// yet, the English text is shown instead, so nothing ever breaks.
String tr(String key, [Map<String, String>? params]) {
  final code = appLanguageNotifier.value.code;
  final entry = _strings[key];
  var text = entry?[code] ?? entry?['en'] ?? key;
  params?.forEach((name, value) {
    text = text.replaceAll('{$name}', value);
  });
  return text;
}

const Map<String, Map<String, String>> _strings = {
  // ── Bottom navigation + floating menu ──────────────────
  'nav_dashboard': {'en': 'Dashboard', 'ms': 'Papan Pemuka', 'zh': '首页'},
  'nav_scan': {'en': 'Scan', 'ms': 'Imbas', 'zh': '扫描'},
  'nav_history': {'en': 'History', 'ms': 'Sejarah', 'zh': '历史'},
  'nav_places': {'en': 'Places', 'ms': 'Tempat', 'zh': '地点'},
  'menu_profile': {'en': 'Profile', 'ms': 'Profil', 'zh': '个人资料'},
  'menu_chat': {'en': 'Nutrition Chat', 'ms': 'Sembang Nutrisi', 'zh': '营养聊天'},
  'menu_open': {'en': 'Chat & Profile', 'ms': 'Sembang & Profil', 'zh': '聊天与资料'},
  'menu_close': {'en': 'Close menu', 'ms': 'Tutup menu', 'zh': '关闭菜单'},

  // ── Common ─────────────────────────────────────────────
  'common_toggle_dark': {
    'en': 'Toggle dark mode',
    'ms': 'Tukar mod gelap',
    'zh': '切换深色模式',
  },
  'common_refresh': {'en': 'Refresh', 'ms': 'Muat semula', 'zh': '刷新'},

  // ── Dashboard ──────────────────────────────────────────
  'dash_welcome': {
    'en': 'Welcome back!',
    'ms': 'Selamat kembali!',
    'zh': '欢迎回来！',
  },
  'dash_subtitle': {
    'en': 'Track your nutrition with AI-powered food recognition.',
    'ms': 'Jejaki pemakanan anda dengan pengecaman makanan berkuasa AI.',
    'zh': '通过 AI 食物识别追踪您的营养摄入。',
  },
  'dash_progress': {
    'en': "Today's Progress",
    'ms': 'Kemajuan Hari Ini',
    'zh': '今日进度',
  },
  'ring_left': {'en': 'cal left', 'ms': 'kal berbaki', 'zh': '剩余千卡'},
  'ring_over': {'en': 'cal over', 'ms': 'kal lebih', 'zh': '超出千卡'},
  'stat_calories_today': {
    'en': 'Calories today',
    'ms': 'Kalori hari ini',
    'zh': '今日热量',
  },
  'stat_of_goal': {
    'en': '/ {goal} cal',
    'ms': '/ {goal} kal',
    'zh': '/ {goal} 千卡',
  },
  'stat_total_scans': {
    'en': 'Total scans',
    'ms': 'Jumlah imbasan',
    'zh': '扫描次数',
  },
  'stat_today': {'en': 'today', 'ms': 'hari ini', 'zh': '今天'},
  'goal_label': {
    'en': 'Daily calorie goal',
    'ms': 'Sasaran kalori harian',
    'zh': '每日热量目标',
  },
  'percent_of_goal': {
    'en': '{p}% of daily goal',
    'ms': '{p}% daripada sasaran harian',
    'zh': '已达每日目标的 {p}%',
  },
  'over_message': {
    'en': "You're {n} cal over today's goal",
    'ms': 'Anda melebihi sasaran hari ini sebanyak {n} kal',
    'zh': '今天已超出目标 {n} 千卡',
  },
  'week_title': {'en': 'Last 7 days', 'ms': '7 hari lepas', 'zh': '最近 7 天'},
  'avg_per_day': {
    'en': 'Avg {n} cal/day',
    'ms': 'Purata {n} kal/hari',
    'zh': '平均 {n} 千卡/天',
  },
  'no_data_yet': {'en': 'No data yet', 'ms': 'Belum ada data', 'zh': '暂无数据'},
  'chart_today': {'en': 'Today', 'ms': 'Hari ini', 'zh': '今天'},
  'legend_goal': {
    'en': 'Goal {n} cal',
    'ms': 'Sasaran {n} kal',
    'zh': '目标 {n} 千卡',
  },
  'legend_over': {
    'en': 'Over goal',
    'ms': 'Melebihi sasaran',
    'zh': '超出目标',
  },
  'chart_semantics': {
    'en': 'Calories for the last 7 days, goal {goal}. {summary}',
    'ms': 'Kalori untuk 7 hari lepas, sasaran {goal}. {summary}',
    'zh': '最近 7 天的热量，目标 {goal}。{summary}',
  },
  'chart_day_cal': {
    'en': '{day} {n} calories',
    'ms': '{day} {n} kalori',
    'zh': '{day} {n} 千卡',
  },
  'day_mon': {'en': 'Mon', 'ms': 'Isn', 'zh': '周一'},
  'day_tue': {'en': 'Tue', 'ms': 'Sel', 'zh': '周二'},
  'day_wed': {'en': 'Wed', 'ms': 'Rab', 'zh': '周三'},
  'day_thu': {'en': 'Thu', 'ms': 'Kha', 'zh': '周四'},
  'day_fri': {'en': 'Fri', 'ms': 'Jum', 'zh': '周五'},
  'day_sat': {'en': 'Sat', 'ms': 'Sab', 'zh': '周六'},
  'day_sun': {'en': 'Sun', 'ms': 'Ahd', 'zh': '周日'},
  'dash_scan_now': {
    'en': 'Scan Food Now',
    'ms': 'Imbas Makanan Sekarang',
    'zh': '立即扫描食物',
  },
  'dash_recent': {
    'en': 'Recent Scans',
    'ms': 'Imbasan Terkini',
    'zh': '最近扫描',
  },
  'dash_no_recent': {
    'en': 'No recent scans',
    'ms': 'Tiada imbasan terkini',
    'zh': '暂无最近扫描',
  },
  'scan_item': {
    'en': '{cal} cal · {date}',
    'ms': '{cal} kal · {date}',
    'zh': '{cal} 千卡 · {date}',
  },

  // ── Food scanner ───────────────────────────────────────
  'scan_title': {
    'en': 'Food Scanner',
    'ms': 'Pengimbas Makanan',
    'zh': '食物扫描',
  },
  'scan_heading': {'en': 'Scan Food', 'ms': 'Imbas Makanan', 'zh': '扫描食物'},
  'scan_subtitle': {
    'en': 'Upload a photo to analyze nutrition, allergens & more.',
    'ms': 'Muat naik foto untuk menganalisis nutrisi, alergen dan lain-lain.',
    'zh': '上传照片以分析营养成分、过敏原等。',
  },
  'scan_take_photo': {'en': 'Take Photo', 'ms': 'Ambil Foto', 'zh': '拍照'},
  'scan_use_camera': {
    'en': 'Use camera',
    'ms': 'Guna kamera',
    'zh': '使用相机',
  },
  'scan_gallery': {'en': 'Gallery', 'ms': 'Galeri', 'zh': '相册'},
  'scan_formats': {'en': 'JPG, PNG', 'ms': 'JPG, PNG', 'zh': 'JPG、PNG'},
  'scan_analyzing_food': {
    'en': 'Analyzing food...',
    'ms': 'Menganalisis makanan...',
    'zh': '正在分析食物...',
  },
  'scan_try_again': {'en': 'Try again', 'ms': 'Cuba lagi', 'zh': '重试'},
  'scan_analyzing': {
    'en': 'Analyzing...',
    'ms': 'Menganalisis...',
    'zh': '正在分析...',
  },
  'err_timeout': {
    'en': 'Analysis took too long. Check your connection and try again.',
    'ms':
        'Analisis mengambil masa terlalu lama. Semak sambungan anda dan cuba lagi.',
    'zh': '分析时间过长，请检查网络连接后重试。',
  },
  'err_network': {
    'en': 'No internet connection. Check your connection and try again.',
    'ms': 'Tiada sambungan internet. Semak sambungan anda dan cuba lagi.',
    'zh': '没有网络连接，请检查网络后重试。',
  },
  'err_rate': {
    'en': 'Too many requests right now. Please wait a minute and try again.',
    'ms': 'Terlalu banyak permintaan sekarang. Sila tunggu seminit dan cuba lagi.',
    'zh': '请求过于频繁，请稍等一分钟后重试。',
  },
  'err_key': {
    'en':
        'The AI service rejected the request. The API key may be missing or wrong.',
    'ms':
        'Perkhidmatan AI menolak permintaan. Kunci API mungkin tiada atau salah.',
    'zh': 'AI 服务拒绝了请求，API 密钥可能缺失或错误。',
  },
  'err_busy': {
    'en': 'The AI service is busy right now. Please try again in a moment.',
    'ms': 'Perkhidmatan AI sibuk sekarang. Sila cuba lagi sebentar lagi.',
    'zh': 'AI 服务当前繁忙，请稍后再试。',
  },
  'err_generic': {
    'en': "Couldn't analyze this image. Please try again.",
    'ms': 'Tidak dapat menganalisis imej ini. Sila cuba lagi.',
    'zh': '无法分析这张图片，请重试。',
  },
  'scan_serving': {
    'en': 'Serving: {s}',
    'ms': 'Hidangan: {s}',
    'zh': '份量：{s}',
  },
  'scan_est_cal': {
    'en': 'Estimated Calories',
    'ms': 'Anggaran Kalori',
    'zh': '估计热量',
  },
  'scan_nutrition': {
    'en': 'Nutrition Breakdown',
    'ms': 'Pecahan Nutrisi',
    'zh': '营养成分',
  },
  'nut_protein': {'en': 'Protein', 'ms': 'Protein', 'zh': '蛋白质'},
  'nut_carbs': {'en': 'Carbs', 'ms': 'Karbohidrat', 'zh': '碳水化合物'},
  'nut_fat': {'en': 'Fat', 'ms': 'Lemak', 'zh': '脂肪'},
  'nut_fiber': {'en': 'Fiber', 'ms': 'Serat', 'zh': '膳食纤维'},
  'nut_sugar': {'en': 'Sugar', 'ms': 'Gula', 'zh': '糖'},
  'nut_sodium': {'en': 'Sodium', 'ms': 'Natrium', 'zh': '钠'},
  'scan_allergens': {'en': 'Allergens', 'ms': 'Alergen', 'zh': '过敏原'},
  'scan_none_detected': {
    'en': 'None detected',
    'ms': 'Tiada dikesan',
    'zh': '未检测到',
  },
  'scan_diet_tags': {'en': 'Diet Tags', 'ms': 'Tag Diet', 'zh': '饮食标签'},
  'scan_ingredients': {'en': 'Ingredients', 'ms': 'Bahan', 'zh': '配料'},

  // ── Common buttons ─────────────────────────────────────
  'common_cancel': {'en': 'Cancel', 'ms': 'Batal', 'zh': '取消'},

  // ── Nutrition chat ─────────────────────────────────────
  'chat_title': {'en': 'Nutrition Chat', 'ms': 'Sembang Nutrisi', 'zh': '营养聊天'},
  'chat_welcome': {
    'en':
        "Hi! I'm your nutrition assistant. Ask me about food, calories, or healthy eating. Type a question or tap a suggestion below.",
    'ms':
        'Hai! Saya pembantu nutrisi anda. Tanya saya tentang makanan, kalori atau pemakanan sihat. Taip soalan atau ketik cadangan di bawah.',
    'zh': '你好！我是你的营养助手。可以问我关于食物、热量或健康饮食的问题。输入问题或点击下方的建议。',
  },
  'chat_q1': {
    'en': 'How many calories in an avocado?',
    'ms': 'Berapa kalori dalam sebiji alpukat?',
    'zh': '一个牛油果有多少热量？',
  },
  'chat_q2': {
    'en': 'Best protein sources?',
    'ms': 'Sumber protein terbaik?',
    'zh': '最好的蛋白质来源？',
  },
  'chat_q3': {
    'en': 'Is brown rice healthier?',
    'ms': 'Adakah nasi perang lebih sihat?',
    'zh': '糙米更健康吗？',
  },
  'chat_q4': {
    'en': 'How much water daily?',
    'ms': 'Berapa banyak air sehari?',
    'zh': '每天应该喝多少水？',
  },
  'chat_q5': {
    'en': 'Healthy breakfast ideas',
    'ms': 'Idea sarapan sihat',
    'zh': '健康早餐点子',
  },
  'chat_q6': {
    'en': 'Foods for weight loss',
    'ms': 'Makanan untuk menurunkan berat badan',
    'zh': '减肥食物',
  },
  'chat_name': {
    'en': 'Nutrition Assistant',
    'ms': 'Pembantu Nutrisi',
    'zh': '营养助手',
  },
  'chat_hint': {
    'en': 'Ask about nutrition...',
    'ms': 'Tanya tentang nutrisi...',
    'zh': '询问营养问题...',
  },
  'chat_hint_waiting': {
    'en': 'Waiting for answer...',
    'ms': 'Menunggu jawapan...',
    'zh': '等待回答中...',
  },
  'chat_clear': {'en': 'Clear', 'ms': 'Kosongkan', 'zh': '清除'},
  'chat_send': {'en': 'Send message', 'ms': 'Hantar mesej', 'zh': '发送消息'},
  'chat_disclaimer': {
    'en': 'Nutrition values are estimates, not medical advice.',
    'ms': 'Nilai nutrisi adalah anggaran, bukan nasihat perubatan.',
    'zh': '营养数值仅为估计，不构成医疗建议。',
  },
  'chat_thinking': {
    'en': 'Thinking...',
    'ms': 'Sedang berfikir...',
    'zh': '思考中...',
  },
  'chat_copy': {'en': 'Copy answer', 'ms': 'Salin jawapan', 'zh': '复制回答'},
  'chat_copied': {
    'en': 'Copied to clipboard',
    'ms': 'Disalin ke papan keratan',
    'zh': '已复制到剪贴板',
  },
  'chat_you': {'en': 'You', 'ms': 'Anda', 'zh': '你'},
  'chat_err_timeout': {
    'en': 'Sorry, that took too long. Please check your connection and try again.',
    'ms':
        'Maaf, ia mengambil masa terlalu lama. Sila semak sambungan anda dan cuba lagi.',
    'zh': '抱歉，这花了太长时间。请检查网络连接后重试。',
  },
  'chat_err_generic': {
    'en':
        "Sorry, I couldn't get an answer right now. Please try again in a moment.",
    'ms':
        'Maaf, saya tidak dapat memberi jawapan sekarang. Sila cuba lagi sebentar lagi.',
    'zh': '抱歉，现在无法获得回答。请稍后再试。',
  },

  // ── Profile ────────────────────────────────────────────
  'prof_title': {'en': 'Your Profile', 'ms': 'Profil Anda', 'zh': '个人资料'},
  'prof_subtitle': {
    'en': 'Manage your account and personal info.',
    'ms': 'Urus akaun dan maklumat peribadi anda.',
    'zh': '管理您的账户和个人信息。',
  },
  'prof_add_name': {
    'en': 'Add your name',
    'ms': 'Tambah nama anda',
    'zh': '添加您的名字',
  },
  'prof_guest_user': {
    'en': 'Guest User',
    'ms': 'Pengguna Tetamu',
    'zh': '访客用户',
  },
  'prof_email_verified': {
    'en': 'Email verified',
    'ms': 'E-mel disahkan',
    'zh': '邮箱已验证',
  },
  'prof_email_not_verified': {
    'en': 'Email not verified',
    'ms': 'E-mel belum disahkan',
    'zh': '邮箱未验证',
  },
  'prof_guest_badge': {
    'en': 'Guest account — limited features',
    'ms': 'Akaun tetamu — ciri terhad',
    'zh': '访客账户 — 功能有限',
  },
  'prof_resend': {
    'en': 'Resend verification email',
    'ms': 'Hantar semula e-mel pengesahan',
    'zh': '重新发送验证邮件',
  },
  'prof_edit': {'en': 'Edit profile', 'ms': 'Sunting profil', 'zh': '编辑资料'},
  'prof_goal_section': {
    'en': 'Nutrition goal',
    'ms': 'Sasaran nutrisi',
    'zh': '营养目标',
  },
  'prof_goal_sub': {
    'en': '{n} cal per day · tap to change or calculate',
    'ms': '{n} kal sehari · ketik untuk ubah atau kira',
    'zh': '每天 {n} 千卡 · 点击修改或计算',
  },
  'prof_lang_section': {'en': 'Language', 'ms': 'Bahasa', 'zh': '语言'},
  'prof_lang_sub': {
    'en': 'AI answers use this language · tap to change',
    'ms': 'Jawapan AI guna bahasa ini · ketik untuk tukar',
    'zh': 'AI 回答将使用此语言 · 点击更改',
  },
  'prof_lang_set': {
    'en': 'Language set to {name}.',
    'ms': 'Bahasa ditetapkan kepada {name}.',
    'zh': '语言已设置为 {name}。',
  },
  'prof_security': {'en': 'Security', 'ms': 'Keselamatan', 'zh': '安全'},
  'prof_change_pw': {
    'en': 'Change password',
    'ms': 'Tukar kata laluan',
    'zh': '修改密码',
  },
  'prof_guest_na': {
    'en': 'Not available for guest accounts',
    'ms': 'Tidak tersedia untuk akaun tetamu',
    'zh': '访客账户不可用',
  },
  'prof_cur_pw': {
    'en': 'Current password',
    'ms': 'Kata laluan semasa',
    'zh': '当前密码',
  },
  'prof_cur_pw_req': {
    'en': 'Enter your current password',
    'ms': 'Masukkan kata laluan semasa anda',
    'zh': '请输入当前密码',
  },
  'prof_forgot': {
    'en': 'Forgot current password?',
    'ms': 'Lupa kata laluan semasa?',
    'zh': '忘记当前密码？',
  },
  'prof_new_pw': {
    'en': 'New password',
    'ms': 'Kata laluan baharu',
    'zh': '新密码',
  },
  'prof_pw_helper': {
    'en': 'At least {n} characters',
    'ms': 'Sekurang-kurangnya {n} aksara',
    'zh': '至少 {n} 个字符',
  },
  'prof_new_pw_req': {
    'en': 'Enter a new password',
    'ms': 'Masukkan kata laluan baharu',
    'zh': '请输入新密码',
  },
  'prof_pw_min': {
    'en': 'Must be at least {n} characters',
    'ms': 'Mesti sekurang-kurangnya {n} aksara',
    'zh': '至少需要 {n} 个字符',
  },
  'prof_pw_differ': {
    'en': 'New password must differ from current',
    'ms': 'Kata laluan baharu mesti berbeza daripada yang semasa',
    'zh': '新密码必须与当前密码不同',
  },
  'prof_confirm_pw': {
    'en': 'Confirm new password',
    'ms': 'Sahkan kata laluan baharu',
    'zh': '确认新密码',
  },
  'prof_pw_mismatch': {
    'en': 'Passwords do not match',
    'ms': 'Kata laluan tidak sepadan',
    'zh': '两次密码不一致',
  },
  'prof_update_pw': {
    'en': 'Update Password',
    'ms': 'Kemas kini Kata Laluan',
    'zh': '更新密码',
  },
  'prof_show_pw': {
    'en': 'Show password',
    'ms': 'Tunjukkan kata laluan',
    'zh': '显示密码',
  },
  'prof_hide_pw': {
    'en': 'Hide password',
    'ms': 'Sembunyikan kata laluan',
    'zh': '隐藏密码',
  },
  'prof_account': {'en': 'Account', 'ms': 'Akaun', 'zh': '账户'},
  'prof_logout': {'en': 'Log out', 'ms': 'Log keluar', 'zh': '退出登录'},
  'prof_logout_title': {'en': 'Log out?', 'ms': 'Log keluar?', 'zh': '退出登录？'},
  'prof_logout_msg': {
    'en': "You'll need to sign in again to access your account.",
    'ms': 'Anda perlu log masuk semula untuk mengakses akaun anda.',
    'zh': '您需要重新登录才能访问您的账户。',
  },
  'prof_delete': {
    'en': 'Request account deletion',
    'ms': 'Mohon pemadaman akaun',
    'zh': '申请删除账户',
  },
  'prof_delete_sub': {
    'en': 'Permanently remove your account and data',
    'ms': 'Padam akaun dan data anda secara kekal',
    'zh': '永久删除您的账户和数据',
  },
  'prof_delete_title': {
    'en': 'Request account deletion?',
    'ms': 'Mohon pemadaman akaun?',
    'zh': '申请删除账户？',
  },
  'prof_delete_msg': {
    'en':
        'You will be signed out and a request to permanently delete your account and data will be sent. This cannot be undone.',
    'ms':
        'Anda akan dilog keluar dan permintaan untuk memadam akaun dan data anda secara kekal akan dihantar. Ini tidak boleh dibatalkan.',
    'zh': '您将被退出登录，并发送永久删除账户和数据的申请。此操作无法撤销。',
  },
  'prof_delete_confirm': {
    'en': 'Request deletion',
    'ms': 'Mohon pemadaman',
    'zh': '申请删除',
  },
  'prof_snack_load_err': {
    'en': 'Could not load your profile. Please try again.',
    'ms': 'Tidak dapat memuatkan profil anda. Sila cuba lagi.',
    'zh': '无法加载您的资料，请重试。',
  },
  'prof_snack_verif_sent': {
    'en': 'Verification email sent to {email}.',
    'ms': 'E-mel pengesahan dihantar ke {email}.',
    'zh': '验证邮件已发送至 {email}。',
  },
  'prof_snack_verif_fail': {
    'en': 'Could not send the email. Please try again later.',
    'ms': 'Tidak dapat menghantar e-mel. Sila cuba lagi kemudian.',
    'zh': '无法发送邮件，请稍后再试。',
  },
  'prof_snack_reset_sent': {
    'en': 'Password reset email sent to {email}.',
    'ms': 'E-mel tetapan semula kata laluan dihantar ke {email}.',
    'zh': '重置密码邮件已发送至 {email}。',
  },
  'prof_snack_reset_fail': {
    'en': 'Could not send the reset email. Please try again later.',
    'ms': 'Tidak dapat menghantar e-mel tetapan semula. Sila cuba lagi kemudian.',
    'zh': '无法发送重置邮件，请稍后再试。',
  },
  'prof_snack_guest_pw': {
    'en': "Password changes aren't available for guest accounts.",
    'ms': 'Pertukaran kata laluan tidak tersedia untuk akaun tetamu.',
    'zh': '访客账户无法修改密码。',
  },
  'prof_snack_pw_ok': {
    'en': 'Password updated successfully!',
    'ms': 'Kata laluan berjaya dikemas kini!',
    'zh': '密码更新成功！',
  },
  'prof_snack_pw_wrong': {
    'en': 'Current password is incorrect.',
    'ms': 'Kata laluan semasa tidak betul.',
    'zh': '当前密码不正确。',
  },
  'prof_snack_pw_fail': {
    'en': 'Could not update your password. Please try again.',
    'ms': 'Tidak dapat mengemas kini kata laluan anda. Sila cuba lagi.',
    'zh': '无法更新密码，请重试。',
  },
  'prof_snack_generic': {
    'en': 'Something went wrong. Please try again.',
    'ms': 'Sesuatu telah berlaku. Sila cuba lagi.',
    'zh': '出了点问题，请重试。',
  },
  'prof_snack_delete_ok': {
    'en': 'Deletion requested. You have been signed out.',
    'ms': 'Pemadaman dimohon. Anda telah dilog keluar.',
    'zh': '已提交删除申请，您已退出登录。',
  },
  'prof_snack_delete_fail': {
    'en': 'Could not send the deletion request. Please try again.',
    'ms': 'Tidak dapat menghantar permintaan pemadaman. Sila cuba lagi.',
    'zh': '无法提交删除申请，请重试。',
  },
  'prof_snack_goal_ok': {
    'en': 'Daily goal set to {n} cal.',
    'ms': 'Sasaran harian ditetapkan kepada {n} kal.',
    'zh': '每日目标已设为 {n} 千卡。',
  },
  'prof_snack_goal_fail': {
    'en': 'Could not save your goal. Please try again.',
    'ms': 'Tidak dapat menyimpan sasaran anda. Sila cuba lagi.',
    'zh': '无法保存目标，请重试。',
  },
  'prof_tap_gallery': {
    'en': 'Tap to choose from gallery',
    'ms': 'Ketik untuk pilih dari galeri',
    'zh': '点击从相册选择',
  },
  'prof_change_photo': {
    'en': 'Change profile photo',
    'ms': 'Tukar foto profil',
    'zh': '更换头像',
  },
  'prof_display_name': {
    'en': 'Display name',
    'ms': 'Nama paparan',
    'zh': '显示名称',
  },
  'prof_name_req': {
    'en': 'Please enter a display name',
    'ms': 'Sila masukkan nama paparan',
    'zh': '请输入显示名称',
  },
  'prof_save_changes': {
    'en': 'Save Changes',
    'ms': 'Simpan Perubahan',
    'zh': '保存更改',
  },
  'prof_pick_fail': {
    'en': 'Could not open your gallery. Please try again.',
    'ms': 'Tidak dapat membuka galeri anda. Sila cuba lagi.',
    'zh': '无法打开相册，请重试。',
  },
  'prof_save_fail': {
    'en': 'Could not save your profile. Please try again.',
    'ms': 'Tidak dapat menyimpan profil anda. Sila cuba lagi.',
    'zh': '无法保存资料，请重试。',
  },

  // ── Calorie goal dialog ────────────────────────────────
  'goal_mode_manual': {'en': 'Enter myself', 'ms': 'Taip sendiri', 'zh': '自己输入'},
  'goal_mode_calc': {'en': 'Calculate', 'ms': 'Kira', 'zh': '计算'},
  'goal_unit': {'en': 'cal', 'ms': 'kal', 'zh': '千卡'},
  'goal_value': {'en': '{n} cal', 'ms': '{n} kal', 'zh': '{n} 千卡'},
  'goal_range_helper': {
    'en': 'Between {min} and {max}',
    'ms': 'Antara {min} dan {max}',
    'zh': '范围 {min} 至 {max}',
  },
  'goal_range_err': {
    'en': 'Enter a number between {min} and {max}',
    'ms': 'Masukkan nombor antara {min} dan {max}',
    'zh': '请输入 {min} 到 {max} 之间的数字',
  },
  'goal_sex': {'en': 'Sex', 'ms': 'Jantina', 'zh': '性别'},
  'goal_male': {'en': 'Male', 'ms': 'Lelaki', 'zh': '男'},
  'goal_female': {'en': 'Female', 'ms': 'Perempuan', 'zh': '女'},
  'goal_age': {'en': 'Age', 'ms': 'Umur', 'zh': '年龄'},
  'goal_years': {'en': 'years', 'ms': 'tahun', 'zh': '岁'},
  'goal_age_err': {
    'en': 'Enter an age from 18 to 90',
    'ms': 'Masukkan umur dari 18 hingga 90',
    'zh': '请输入 18 到 90 岁之间的年龄',
  },
  'goal_height': {'en': 'Height', 'ms': 'Ketinggian', 'zh': '身高'},
  'goal_cm': {'en': 'cm', 'ms': 'cm', 'zh': '厘米'},
  'goal_height_err': {
    'en': 'Enter a height from 120 to 230 cm',
    'ms': 'Masukkan ketinggian dari 120 hingga 230 cm',
    'zh': '请输入 120 到 230 厘米之间的身高',
  },
  'goal_weight': {'en': 'Weight', 'ms': 'Berat', 'zh': '体重'},
  'goal_kg': {'en': 'kg', 'ms': 'kg', 'zh': '公斤'},
  'goal_weight_err': {
    'en': 'Enter a weight from 30 to 250 kg',
    'ms': 'Masukkan berat dari 30 hingga 250 kg',
    'zh': '请输入 30 到 250 公斤之间的体重',
  },
  'goal_activity': {
    'en': 'Activity level',
    'ms': 'Tahap aktiviti',
    'zh': '活动水平',
  },
  'goal_act1': {
    'en': 'Little or no exercise',
    'ms': 'Sedikit atau tiada senaman',
    'zh': '很少或不运动',
  },
  'goal_act2': {
    'en': 'Light (1–3 days/week)',
    'ms': 'Ringan (1–3 hari/minggu)',
    'zh': '轻度（每周 1–3 天）',
  },
  'goal_act3': {
    'en': 'Moderate (3–5 days/week)',
    'ms': 'Sederhana (3–5 hari/minggu)',
    'zh': '中度（每周 3–5 天）',
  },
  'goal_act4': {
    'en': 'Very active (6–7 days/week)',
    'ms': 'Sangat aktif (6–7 hari/minggu)',
    'zh': '高强度（每周 6–7 天）',
  },
  'goal_aim': {'en': 'My aim', 'ms': 'Matlamat saya', 'zh': '我的目标'},
  'goal_aim_lose': {
    'en': 'Lose weight',
    'ms': 'Kurangkan berat badan',
    'zh': '减重',
  },
  'goal_aim_keep': {'en': 'Maintain', 'ms': 'Kekalkan', 'zh': '保持'},
  'goal_aim_gain': {
    'en': 'Gain weight',
    'ms': 'Tambah berat badan',
    'zh': '增重',
  },
  'goal_fill_all': {
    'en': 'Fill in all fields to see your estimate',
    'ms': 'Isi semua medan untuk melihat anggaran anda',
    'zh': '填写所有项目以查看估算',
  },
  'goal_estimated': {
    'en': 'Your estimated daily goal',
    'ms': 'Sasaran harian anggaran anda',
    'zh': '您的每日目标估算',
  },
  'goal_disclaimer': {
    'en':
        'A general estimate only, not medical advice. Talk to a doctor or dietitian for personal guidance.',
    'ms':
        'Anggaran umum sahaja, bukan nasihat perubatan. Bincang dengan doktor atau pakar diet untuk panduan peribadi.',
    'zh': '仅为一般估算，不构成医疗建议。如需个人指导，请咨询医生或营养师。',
  },
  'goal_save': {'en': 'Save goal', 'ms': 'Simpan sasaran', 'zh': '保存目标'},
};