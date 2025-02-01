import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lote0130/features/home/models/note.dart';
import 'package:lote0130/features/home/note_provider.dart';
import 'package:lote0130/features/home/widgets/note_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';
import '../../core/providers/providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _textController = TextEditingController();
  final _contextController = TextEditingController();

  List<String> _tags = ['O'];
  String _selectedTag = 'O';

  List<String> _langs = [];
  int _currentLanguagePage = 0;

  Future<void> _saveCurrentPage(int currentPage) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentPage', currentPage);
  }

  Future<void> _loadCurrentPage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _currentLanguagePage = prefs.getInt('currentPage') ?? 0;
  }

  @override
  void initState() {
    super.initState();
    // 在组件初始化时加载笔记
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotes();
    });
  }

  Future<void> _loadNotes() async {
    final authState = ref.read(authStateProvider).value;
    final profile = ref.read(currentProfileProvider).value;
    final userId = authState?.session != null ? profile?.supabaseId : null;
    print('加载笔记，userId: $userId');
    await ref.read(noteProvider.notifier).loadNotes(userId);

    _langs = profile?.languageCodes ?? [];
    _tags.addAll(profile?.tags ?? []);
  }

  List<String> _getLanguageCodes(String initialLang) {
    if (_langs.length <= 5) {
      final result = List<String>.from(_langs);
      return result;
    }
    List<String> newLangs = List<String>.from(_langs);
    newLangs.remove(initialLang);

    final startIndex = _currentLanguagePage * 4;

    if (startIndex >= newLangs.length) {
      // Reset to first page if somehow we're out of bounds
      _currentLanguagePage = 0;
      return newLangs.sublist(0, 4)..insert(0, initialLang);
    }
    // Take up to 5 languages from current position, or whatever remains
    return newLangs.sublist(startIndex,
        (startIndex + 4) > newLangs.length ? newLangs.length : startIndex + 4)
      ..insert(0, initialLang);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final profileAsync = ref.watch(currentProfileProvider);

    // 当用户状态改变时重新加载笔记
    ref.listen(authStateProvider, (previous, next) {
      _loadNotes();
    });

    ref.listen(currentProfileProvider, (previous, next) {
      next.whenData((profile) {
        _loadNotes();
      });
    });

    return Scaffold(
        appBar: AppBar(
          title: const Text('笔记'),
          actions: [
            // 设置按钮
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                // TODO: 实现设置页面
              },
            ),
            authState.when(
              data: (state) {
                if (state.session != null) {
                  return IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () {
                      ref.read(authRepositoryProvider).signOut();
                    },
                  );
                } else {
                  return IconButton(
                    icon: const Icon(Icons.login),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                  );
                }
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
                context: context,
                builder: (context) => Column(
                      children: [
                        TextField(
                          controller: _textController,
                          autofocus: true,
                        ),
                        ElevatedButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              if (_textController.text.trim().isNotEmpty) {
                                final text = _textController.text.trim();
                                final context =
                                    _contextController.text.trim().isNotEmpty
                                        ? _contextController.text.trim()
                                        : null;
                                _textController.clear();
                                _contextController.clear();

                                // 检查用户是否登录
                                final authState =
                                    ref.read(authStateProvider).value;
                                final userId = authState?.session != null
                                    ? profileAsync.value?.supabaseId
                                    : null;

                                await ref.read(noteProvider.notifier).addNote(
                                    userId,
                                    context,
                                    text,
                                    'zh',
                                    ['tag1', 'tag2']);
                              }
                            },
                            child: Text('提交'))
                      ],
                    ));
          },
          child: const Icon(Icons.add),
        ),
        body: profileAsync.when(
          data: (profile) {
            final notes = ref.watch(noteProvider);
            if (notes.isEmpty) {
              return Center(child: Text('没有笔记，${profile?.createdAt}'));
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 48,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _tags.length,
                    itemBuilder: (context, index) {
                      return FilterChip(
                        side: BorderSide.none,
                        label: Text(_tags[index]),
                        visualDensity: VisualDensity.compact,
                        showCheckmark: false,
                        onSelected: (bool value) {
                          setState(() {
                            _selectedTag = _tags[index];
                          });
                        },
                        selected: _selectedTag == _tags[index],
                      );
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.only(left: 16, right: 16, bottom: 70),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];

                      final initialLang = note.initialLang!;

                      final langs = _getLanguageCodes(initialLang);

                      if (langs.contains(initialLang)) {
                        langs.removeWhere((lang) => lang == initialLang);
                        langs.insert(0, initialLang);
                      } else if (langs.contains('')) {
                        langs.removeWhere((l) => l == '');
                        langs.insert(0, initialLang);
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: SlidableAutoTriggerItem(
                          note: note,
                          child: NoteItem(
                            note: note,
                            langs: langs,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('加载失败:$error')),
        ));
  }
}

class SlidableAutoTriggerItem extends ConsumerStatefulWidget {
  final Widget child;
  final Note note;

  const SlidableAutoTriggerItem({
    super.key,
    required this.child,
    required this.note,
  });

  @override
  ConsumerState<SlidableAutoTriggerItem> createState() =>
      _SlidableAutoTriggerItemState();
}

class _SlidableAutoTriggerItemState
    extends ConsumerState<SlidableAutoTriggerItem>
    with SingleTickerProviderStateMixin {
  bool _hasTriggered = false;
  bool _hasHapticFeedback = false;
  late final SlidableController _controller;
  final double _extentRatio = 0.15;
  double _lastProgress = 0;
  bool _isSliding = false;

  @override
  void initState() {
    super.initState();
    _controller = SlidableController(this);
    _controller.animation.addListener(_checkProgress);
  }

  @override
  void dispose() {
    _controller.animation.removeListener(_checkProgress);
    _controller.dispose();
    super.dispose();
  }

  void _checkProgress() {
    final progress = _controller.animation.value;

    // 开始滑动
    if (!_isSliding && progress.abs() > 0) {
      _isSliding = true;
    }

    // 只在首次超过阈值时触发haptic
    if (progress.abs() >= _extentRatio &&
        _lastProgress.abs() < _extentRatio &&
        !_hasTriggered) {
      _hasHapticFeedback = true;
      HapticFeedback.mediumImpact();
    }

    // 检测滑动结束
    if (_isSliding && progress.abs() == 0) {
      _isSliding = false;
      _hasHapticFeedback = false;
    }

    // 如果滑动停止但没有完全展开，自动回弹
    if (_isSliding &&
        progress == _lastProgress &&
        progress.abs() > 0 &&
        progress.abs() < _extentRatio * 1.2) {
      _controller.close();
    }

    _lastProgress = progress;
  }

  Future<void> _closeWithAnimation() async {
    _controller.close();
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(widget.note.id),
      controller: _controller,
      startActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: _extentRatio,
        openThreshold: _extentRatio * 1.2,
        dismissible: DismissiblePane(
          onDismissed: () {},
          closeOnCancel: true,
          dismissThreshold: _extentRatio,
          confirmDismiss: () async {
            if (!_hasTriggered) {
              setState(() => _hasTriggered = true);
              await _closeWithAnimation();
              if (!mounted) return false;

              final BuildContext currentContext = context;
              // await showModalBottomSheet(
              //   context: currentContext,
              //   isScrollControlled: true,
              //   backgroundColor: Colors.white,
              //   builder: (context) => NoteInputSheet(note: widget.note),
              // );

              if (!mounted) return false;
              setState(() {
                _hasTriggered = false;
                _hasHapticFeedback = false;
              });
            }
            return false;
          },
        ),
        children: [
          CustomSlidableAction(
            onPressed: (_) {},
            autoClose: true,
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(16),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Colors.white,
            child: const Text(
              '编辑',
              style: TextStyle(color: Colors.black, fontSize: 20),
            ),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: _extentRatio,
        openThreshold: _extentRatio * 1.2,
        dismissible: DismissiblePane(
          onDismissed: () {},
          closeOnCancel: true,
          dismissThreshold: _extentRatio,
          confirmDismiss: () async {
            if (!_hasTriggered) {
              setState(() => _hasTriggered = true);
              await _closeWithAnimation();
              if (!mounted) return false;

              final BuildContext currentContext = context;
              bool? confirm = await showDialog<bool>(
                context: currentContext,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('确认删除'),
                    content: const Text('你确定要删除该笔记吗？'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('删除'),
                      ),
                    ],
                  );
                },
              );

              if (!mounted) return false;

              if (confirm ?? false) {
                ref.read(noteProvider.notifier).deleteNote(widget.note);
                if (!mounted) return false;
                ScaffoldMessenger.of(currentContext).showSnackBar(
                  const SnackBar(content: Text('笔记已删除')),
                );
              }
              setState(() {
                _hasTriggered = false;
                _hasHapticFeedback = false;
              });
            }
            return false;
          },
        ),
        children: [
          CustomSlidableAction(
            onPressed: (_) {},
            autoClose: true,
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(16),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            child: const Text(
              '删除',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
        ],
      ),
      child: widget.child,
    );
  }
}
