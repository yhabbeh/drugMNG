import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:drug/features/adherence/domain/entities/adherence_range.dart';
import 'package:drug/features/adherence/presentation/bloc/adherence_bloc.dart';
import 'package:drug/features/adherence/presentation/bloc/adherence_event.dart';

class AdherenceRangeSelector extends StatelessWidget {
  const AdherenceRangeSelector({super.key, required this.current});

  final AdherenceRange current;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<AdherenceRange>(
      segments: AdherenceRange.values
          .map(
            (r) => ButtonSegment<AdherenceRange>(
              value: r,
              label: Text(r.label),
            ),
          )
          .toList(),
      selected: {current},
      showSelectedIcon: false,
      onSelectionChanged: (sel) {
        if (sel.isEmpty) return;
        context.read<AdherenceBloc>().add(AdherenceRangeChanged(sel.first));
      },
    );
  }
}
