import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../app_colors.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';

class PendingVerificationScreen extends StatefulWidget {
  final VerificationStatus status;
  final String? rejectionReason;
  final UserRole role;

  const PendingVerificationScreen({
    super.key,
    required this.status,
    required this.role,
    this.rejectionReason,
  });

  @override
  State<PendingVerificationScreen> createState() =>
      _PendingVerificationScreenState();
}

class _PendingVerificationScreenState
    extends State<PendingVerificationScreen> {
  bool _refreshing = false;

  Future<void> _checkStatus() async {
    setState(() => _refreshing = true);
    await context.read<AuthProvider>().refreshProfile();
    // If approved, _Root will rebuild and navigate away automatically.
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final isPending  = widget.status == VerificationStatus.pending;
    final isRejected = widget.status == VerificationStatus.rejected;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            children: [
              // ── Top bar ─────────────────────────────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Symbols.logout, size: 18),
                  label: const Text('Logout'),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  onPressed: () => context.read<AuthProvider>().logout(),
                ),
              ),

              const Spacer(),

              // ── Illustration ────────────────────────────────────────────
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPending
                      ? Colors.orange.shade50
                      : Colors.red.shade50,
                ),
                child: Icon(
                  isPending ? Symbols.hourglass_empty : Symbols.cancel,
                  size: 56,
                  color: isPending ? Colors.orange : Colors.red,
                ),
              ),
              const SizedBox(height: 28),

              // ── Headline ────────────────────────────────────────────────
              Text(
                isPending ? 'Application Under Review' : 'Application Rejected',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // ── Role pill ───────────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: kOrangeLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  roleLabel(widget.role),
                  style: const TextStyle(
                      color: kOrange,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 20),

              // ── Body text ───────────────────────────────────────────────
              Text(
                isPending
                    ? 'Your service-provider application has been submitted '
                        'and is currently being reviewed by our admin team.\n\n'
                        'You will be notified as soon as a decision is made. '
                        'This usually takes less than 24 hours.'
                    : 'Unfortunately your application was not approved this time.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey.shade600, height: 1.5),
              ),

              // ── Rejection reason box ─────────────────────────────────────
              if (isRejected && widget.rejectionReason != null) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Symbols.info,
                            size: 16, color: Colors.red.shade600),
                        const SizedBox(width: 6),
                        Text('Reason from admin',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                                fontSize: 13)),
                      ]),
                      const SizedBox(height: 6),
                      Text(
                        widget.rejectionReason!,
                        style: TextStyle(
                            color: Colors.red.shade700, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // ── Actions ──────────────────────────────────────────────────
              if (isPending) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: _refreshing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Symbols.refresh),
                    label: const Text('Check status'),
                    onPressed: _refreshing ? null : _checkStatus,
                  ),
                ),
                const SizedBox(height: 10),
              ],

              if (isRejected) ...[
                // Guidance for re-applying (contact support or re-register)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Symbols.mail),
                    label: const Text('Contact support'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please email support@camplink.app'),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // ── Timeline steps (pending only) ───────────────────────────
              if (isPending) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 12),
                _StepRow(
                    step: 1,
                    label: 'Application submitted',
                    done: true),
                _StepRow(
                    step: 2,
                    label: 'Admin review',
                    done: false),
                _StepRow(
                    step: 3,
                    label: 'Account activated',
                    done: false),
              ],

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Timeline step row ─────────────────────────────────────────────────────────

class _StepRow extends StatelessWidget {
  final int step;
  final String label;
  final bool done;
  const _StepRow(
      {required this.step, required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? kOrange : Colors.grey.shade200,
          ),
          child: done
              ? const Icon(Symbols.check, color: Colors.white, size: 16)
              : Center(
                  child: Text('$step',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade500)),
                ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
              fontSize: 13,
              color: done ? Colors.black87 : Colors.grey,
              fontWeight:
                  done ? FontWeight.w600 : FontWeight.normal),
        ),
      ]),
    );
  }
}
