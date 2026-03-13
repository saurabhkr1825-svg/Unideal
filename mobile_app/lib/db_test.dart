import 'dart:io';
import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://luooikdggmiwbgdzoubv.supabase.co',
    'sb_publishable_5EPrVD9AJ78Wgc0Mqp-XHw_y9YtLsX-',
  );

  try {
    print("Testing getFundReleaseRequests query...");
    var query = supabase
        .from('transactions')
        .select('*, profiles(full_name), donations(title)')
        .eq('status', 'waiting_admin_approval')
        .order('created_at', ascending: true);
        
    final res = await query;
    print("Success: ${res.length} items");
    print(res);
  } catch (e) {
    print("Error: $e");
  }

  exit(0);
}
