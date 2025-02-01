import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lote0130/core/providers/language_provider.dart';
import 'package:lote0130/features/home/models/note.dart';
import 'package:intl/intl.dart';

class NoteItem extends ConsumerWidget {
  final Note note;
  final List<String> langs;

  const NoteItem({
    super.key,
    required this.note,
    required this.langs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  DateFormat('yy/M/dd HH:mm:ss').format(note.createdAt!),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(color: Colors.grey[600], fontSize: 12),
                ),
                note.isSynced != true
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: const Icon(
                          size: 12,
                          Icons.cloud_outlined,
                          color: Colors.grey,
                        ),
                      )
                    : SizedBox.shrink(),
                Spacer(),
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        final lang = langs[index];
                        final isInitial = lang == note.initialLang;
                        final isCurrent = lang == note.currentLang;
                        final hasTranslation = false;
                        return SizedBox(
                          height: 10,
                          child: ActionChip(
                              side: BorderSide.none,
                              padding: EdgeInsets.zero,
                              visualDensity:
                                  VisualDensity(horizontal: 4, vertical: -4),
                              // VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              tooltip: ref.read(languageNameProvider(lang)),
                              label: Text(
                                ref
                                    .read(languageZhNameProvider(lang))
                                    .substring(0, 1),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isCurrent
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : !hasTranslation
                                          // ? Theme.of(context)
                                          //     .colorScheme
                                          //     .primary
                                          ? Colors.grey[500]
                                          : null,
                                ),
                              ),
                              backgroundColor: isCurrent
                                  ? Theme.of(context).colorScheme.primary
                                  : !hasTranslation
                                      ? Theme.of(context)
                                          .colorScheme
                                          .surfaceContainer
                                      : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                              onPressed: () {}),
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemCount: langs.length),
                )
              ],
            ),
            Text(note.currentContent ?? 'na'),
          ],
        ),
      ),
    );
  }
}
