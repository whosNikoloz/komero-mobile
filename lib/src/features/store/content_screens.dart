import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../data/admin_repositories.dart';
import '../../l10n_ext.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/common.dart';
import '../../widgets/editor.dart';
import '../../widgets/sheet.dart';

// ─── Blog ────────────────────────────────────────────────────────────────────

final blogPostsProvider = FutureProvider<List<BlogPost>>(
  (ref) => ref.watch(blogRepositoryProvider).posts(),
);

/// Writing and publishing posts. A post is created as a draft, so one can be
/// written on the move and published later from either the phone or the web.
class BlogScreen extends ConsumerWidget {
  const BlogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final c = context.c;
    final posts = ref.watch(blogPostsProvider);

    return AppScaffold(
      title: l.blog,
      actions: [
        IconButton(
          tooltip: l.addNew,
          onPressed: () => _edit(context, ref),
          icon: const Icon(Icons.add),
        ),
        const SizedBox(width: 4),
      ],
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(blogPostsProvider);
          await ref.read(blogPostsProvider.future);
        },
        child: AsyncView(
          value: posts,
          onRetry: () => ref.invalidate(blogPostsProvider),
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(message: l.noResults, icon: Icons.article_outlined);
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, indent: 16, color: c.border),
              itemBuilder: (_, i) {
                final post = items[i];

                return ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
                  title: Text(
                    post.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: c.text,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: StatusDot(
                      label: post.isPublished ? l.published : l.statusDraft,
                      color: post.isPublished ? c.success : c.textMuted,
                    ),
                  ),
                  trailing: _PostActions(post: post),
                  onTap: () => _edit(context, ref, existing: post),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, {
    BlogPost? existing,
  }) async {
    final saved = await showKomeroSheet<bool>(
      context,
      title: existing == null ? context.l.addNew : context.l.edit,
      subtitle: context.l.blog,
      builder: (_) => _PostForm(ref: ref, existing: existing),
    );

    if (saved == true) ref.invalidate(blogPostsProvider);
  }
}

class _PostActions extends ConsumerStatefulWidget {
  const _PostActions({required this.post});

  final BlogPost post;

  @override
  ConsumerState<_PostActions> createState() => _PostActionsState();
}

class _PostActionsState extends ConsumerState<_PostActions> {
  bool _busy = false;

  Future<void> _run(Future<void> Function(BlogRepository repo) action) async {
    setState(() => _busy = true);

    final messenger = ScaffoldMessenger.of(context);

    try {
      await action(ref.read(blogRepositoryProvider));
      ref.invalidate(blogPostsProvider);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final c = context.c;

    if (_busy) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz, color: c.textMuted),
      onSelected: (action) => action == 'publish'
          ? _run((repo) => repo.publish(widget.post.id))
          : _run((repo) => repo.deletePost(widget.post.id)),
      itemBuilder: (_) => [
        if (!widget.post.isPublished)
          PopupMenuItem(value: 'publish', child: Text(l.publish)),
        PopupMenuItem(value: 'delete', child: Text(l.delete)),
      ],
    );
  }
}

class _PostForm extends ConsumerStatefulWidget {
  const _PostForm({required this.ref, this.existing});

  final WidgetRef ref;
  final BlogPost? existing;

  @override
  ConsumerState<_PostForm> createState() => _PostFormState();
}

class _PostFormState extends ConsumerState<_PostForm> {
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _excerpt =
      TextEditingController(text: widget.existing?.excerpt ?? '');
  final _content = TextEditingController();

  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _excerpt.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();

    if (title.isEmpty) return;

    setState(() => _busy = true);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(blogRepositoryProvider);
    final existing = widget.existing;

    try {
      if (existing == null) {
        await repo.createPost(
          title: title,
          content: _content.text,
          excerpt: _excerpt.text.trim(),
        );
      } else {
        await repo.updatePost(
          id: existing.id,
          title: title,
          content: _content.text,
          excerpt: _excerpt.text.trim(),
        );
      }

      navigator.pop(true);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));

      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final c = context.c;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _title,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l.title),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _excerpt,
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l.shortDescription),
        ),
        const SizedBox(height: 4),
        // The body is the long one, so it gets the full-screen editor rather
        // than a box inside a sheet above the keyboard.
        EditorRow(
          label: _content.text.trim().isEmpty
              ? l.addValue(l.postBody)
              : l.postBody,
          value: _content.text,
          onTap: () async {
            final text = await editText(
              context,
              title: l.postBody,
              subtitle: _title.text.trim().isEmpty ? null : _title.text.trim(),
              initial: _content.text,
            );

            if (text == null || !mounted) return;

            setState(() => _content.text = text);
          },
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.primaryForeground,
                  ),
                )
              : Text(l.save),
        ),
      ],
    );
  }
}

// ─── FAQ ─────────────────────────────────────────────────────────────────────

final faqsProvider = FutureProvider<List<Faq>>(
  (ref) => ref.watch(faqRepositoryProvider).list(),
);

class FaqsScreen extends ConsumerWidget {
  const FaqsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final c = context.c;
    final faqs = ref.watch(faqsProvider);

    return AppScaffold(
      title: l.faqs,
      actions: [
        IconButton(
          tooltip: l.addNew,
          onPressed: () => _edit(context, ref),
          icon: const Icon(Icons.add),
        ),
        const SizedBox(width: 4),
      ],
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(faqsProvider);
          await ref.read(faqsProvider.future);
        },
        child: AsyncView(
          value: faqs,
          onRetry: () => ref.invalidate(faqsProvider),
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                message: l.noResults,
                icon: Icons.help_outline,
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, indent: 16, color: c.border),
              itemBuilder: (_, i) {
                final faq = items[i];

                return ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
                  title: Text(
                    faq.question,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: c.text,
                    ),
                  ),
                  subtitle: Text(
                    faq.answer,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: c.textMuted),
                  ),
                  trailing: IconButton(
                    tooltip: l.delete,
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);

                      try {
                        await ref.read(faqRepositoryProvider).delete(faq.id);
                        ref.invalidate(faqsProvider);
                      } catch (e) {
                        messenger.showSnackBar(SnackBar(content: Text('$e')));
                      }
                    },
                    icon: Icon(Icons.delete_outline, size: 20, color: c.textMuted),
                  ),
                  onTap: () => _edit(context, ref, existing: faq),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, {Faq? existing}) async {
    final saved = await showKomeroSheet<bool>(
      context,
      title: existing == null ? context.l.addNew : context.l.edit,
      subtitle: context.l.faqs,
      builder: (_) => _FaqForm(ref: ref, existing: existing),
    );

    if (saved == true) ref.invalidate(faqsProvider);
  }
}

class _FaqForm extends ConsumerStatefulWidget {
  const _FaqForm({required this.ref, this.existing});

  final WidgetRef ref;
  final Faq? existing;

  @override
  ConsumerState<_FaqForm> createState() => _FaqFormState();
}

class _FaqFormState extends ConsumerState<_FaqForm> {
  late final _question =
      TextEditingController(text: widget.existing?.question ?? '');
  late final _answer = TextEditingController(text: widget.existing?.answer ?? '');

  bool _busy = false;

  @override
  void dispose() {
    _question.dispose();
    _answer.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final question = _question.text.trim();
    final answer = _answer.text.trim();

    if (question.isEmpty || answer.isEmpty) return;

    setState(() => _busy = true);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(faqRepositoryProvider).save(
            id: widget.existing?.id,
            question: question,
            answer: answer,
          );

      navigator.pop(true);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));

      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final c = context.c;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _question,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l.question),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _answer,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l.answer),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.primaryForeground,
                  ),
                )
              : Text(l.save),
        ),
      ],
    );
  }
}
