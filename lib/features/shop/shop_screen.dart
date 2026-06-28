import 'package:flutter/material.dart';
import 'package:ascend/core/services/gamification_service.dart';

enum ShopFilter { tous, icons, badges, themes, animations, avatars }

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  ShopFilter _selectedFilter = ShopFilter.tous;

  List<ShopItem> get _filteredItems {
    final all = ShopItem.all;
    switch (_selectedFilter) {
      case ShopFilter.tous:
        return all;
      case ShopFilter.icons:
        return all.where((i) => i.type == 'icon').toList();
      case ShopFilter.badges:
        return all.where((i) => i.type == 'badge').toList();
      case ShopFilter.themes:
        return all.where((i) => i.type == 'theme').toList();
      case ShopFilter.animations:
        return all.where((i) => i.type == 'animation').toList();
      case ShopFilter.avatars:
        return all.where((i) => i.type == 'avatar').toList();
    }
  }

  String _filterLabel(ShopFilter f) {
    switch (f) {
      case ShopFilter.tous:
        return 'Tous';
      case ShopFilter.icons:
        return 'Icônes';
      case ShopFilter.badges:
        return 'Badges';
      case ShopFilter.themes:
        return 'Thèmes';
      case ShopFilter.animations:
        return 'Animations';
      case ShopFilter.avatars:
        return 'Avatars';
    }
  }

  void _onBuy(ShopItem item) {
    if (item.requiredLevel > GamificationService.level) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Niveau requis : ${item.requiredLevel}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    if (GamificationService.coins < item.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pas assez de pièces !'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    _showConfirmDialog(item);
  }

  Future<void> _showConfirmDialog(ShopItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer l\'achat'),
        content: Text('Acheter « ${item.name} » pour ${item.price} pièces ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Acheter'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final success = await GamificationService.spendCoins(item.price);
      if (success) {
        await GamificationService.purchaseItem(item.id);
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('« ${item.name} » acheté !'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Erreur lors de l\'achat.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coins = GamificationService.coins;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Boutique'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 4),
                  Text(
                    '$coins',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              scrollDirection: Axis.horizontal,
              itemCount: ShopFilter.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = ShopFilter.values[index];
                final selected = _selectedFilter == filter;
                return FilterChip(
                  label: Text(_filterLabel(filter)),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedFilter = filter),
                  selectedColor: theme.colorScheme.primaryContainer,
                  checkmarkColor: theme.colorScheme.onPrimaryContainer,
                  labelStyle: TextStyle(
                    color: selected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _filteredItems.isEmpty
                ? const Center(child: Text('Aucun article disponible.'))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          return _ShopItemCard(
                            item: _filteredItems[index],
                            onBuy: _onBuy,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  final ShopItem item;
  final void Function(ShopItem) onBuy;

  const _ShopItemCard({required this.item, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coins = GamificationService.coins;
    final level = GamificationService.level;
    final owned = GamificationService.hasPurchased(item.id);
    final canAfford = coins >= item.price;
    final levelOk = level >= item.requiredLevel;
    final canBuy = canAfford && levelOk && !owned;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              color: theme.colorScheme.surfaceContainerHighest,
              alignment: Alignment.center,
              child: Text(
                item.preview,
                style: const TextStyle(fontSize: 48),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: theme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (owned)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Possédé',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                if (!levelOk)
                  Text(
                    'Niveau requis : ${item.requiredLevel}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        '${item.price}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!canAfford && !owned)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            '(pas assez)',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: canBuy ? () => onBuy(item) : null,
                      child: const Text('Acheter'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
