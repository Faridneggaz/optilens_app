import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/activity_report.dart';
import '../../utils/activity_report_feedback.dart';

typedef ReportLookupResult = ({List<ReportOption> items, bool more});
typedef ReportLookupLoader =
    Future<ReportLookupResult> Function(String query, int offset);

Future<ReportOption?> showReportLookup({
  required BuildContext context,
  required String title,
  required ReportLookupLoader loader,
}) => showModalBottomSheet<ReportOption>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  builder: (_) => ReportLookupSheet(title: title, loader: loader),
);

class ReportLookupSheet extends StatefulWidget {
  const ReportLookupSheet({
    super.key,
    required this.title,
    required this.loader,
  });
  final String title;
  final ReportLookupLoader loader;
  @override
  State<ReportLookupSheet> createState() => _ReportLookupSheetState();
}

class _ReportLookupSheetState extends State<ReportLookupSheet> {
  final _search = TextEditingController();
  Timer? _timer;
  int _generation = 0;
  int _offset = 0;
  List<ReportOption> _items = [];
  bool _loading = true;
  bool _more = false;
  String _error = '';
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    final generation = more ? _generation : ++_generation;
    if (!more) {
      _items = [];
      _offset = 0;
      _more = false;
    }
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final result = await widget.loader(_search.text.trim(), _offset);
      if (!mounted || generation != _generation) return;
      setState(() {
        final known = _items.map((r) => r.value).toSet();
        _items.addAll(result.items.where((r) => !known.contains(r.value)));
        _offset += result.items.length;
        _more = result.more;
      });
    } catch (e) {
      if (mounted && generation == _generation) {
        setState(() => _error = activityReportError(e));
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        height:
            (media.size.height -
                media.viewInsets.bottom -
                media.padding.vertical) *
            .88,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(18, 12, 6, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'ar_close'.tr,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _search,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'ar_search_options'.tr,
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (_) {
                  _generation++;
                  _timer?.cancel();
                  _timer = Timer(
                    const Duration(milliseconds: 300),
                    () => _load(),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _error.isNotEmpty
                  ? SingleChildScrollView(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(_error),
                          ),
                          TextButton(
                            onPressed: () => _load(more: _items.isNotEmpty),
                            child: Text('ar_retry'.tr),
                          ),
                        ],
                      ),
                    )
                  : _loading && _items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                  ? Center(child: Text('ar_no_results'.tr))
                  : ListView.builder(
                      itemCount: _items.length + (_more || _loading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _items.length) {
                          return _loading
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(18),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : TextButton(
                                  onPressed: () => _load(more: true),
                                  child: Text('ar_load_more'.tr),
                                );
                        }
                        final item = _items[index];
                        return ListTile(
                          title: Text(
                            item.label,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: item.label != item.value
                              ? Text(
                                  item.value,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.muted,
                                  ),
                                )
                              : null,
                          trailing: const Icon(Icons.chevron_right, size: 18),
                          onTap: () => Navigator.pop(context, item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
