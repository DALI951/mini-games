import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../services/prefs.dart';
import '../theme.dart';
import '../widgets/game_scaffold.dart';
import '../widgets/result_screen.dart';

/// Stickman Fight — a two-stickman duel on the pit bridge.
///
/// Forced-landscape duel on the pit bridge. Move with the joystick; hold ▲
/// for ~3s to jump; lifting your finger fires ranged weapons; melee blades
/// hurt on contact. Fall into the spikes and you lose the round. First to 3
/// round-falls wins the match.
class StickmanDuelScreen extends StatefulWidget {
  const StickmanDuelScreen({super.key});

  @override
  State<StickmanDuelScreen> createState() => _StickmanDuelScreenState();
}

enum _Weapon {
  knife('Knife', '🔪'),
  sword('Sword', '⚔️'),
  bat('Bat', '🏏'),
  bow('Bow', '🏹'),
  gun('Gun', '🔫'),
  bomb('Bomb', '💣');

  const _Weapon(this.label, this.glyph);

  final String label;
  final String glyph;
}

enum _Phase { weaponSelect, ready, fight, roundOver, matchOver }

class _Fighter {
  _Fighter(this.player);

  /// 1 = left (Player 1 / You), 2 = right (Player 2 / Bot).
  final int player;

  double x = 0; // feet center x
  double y = 0; // feet y (canvas coords, y grows down)
  double vx = 0;
  double vy = 0;
  double rot = 0; // radians
  double vrot = 0;
  bool grounded = true;
  bool dead = false;
  int facing = 1; // 1 = toward the pit / rival, -1 = away
  _Weapon weapon = _Weapon.knife;
  bool launched = false;
  double attackT = -1; // > 0 while the attack animation plays
  double rld = 0; // weapon cooldown
  double hurtT = 0; // contact-damage immunity
  double lungeVx = 0;
  double walk = 0; // walk animation phase
  double thinkT = 0;
  double poc = 0; // phase timer for the bot weapon pick
  bool moveL = false;
  bool moveR = false;
}

class _Shot {
  _Shot(this.x, this.y, this.vx, this.vy, this.owner, this.kind);

  double x;
  double y;
  final double vx;
  double vy;
  final int owner; // 1 or 2
  final int kind; // 0 bullet, 1 arrow, 2 bomb
  double fuse = 1.4;
}

class _Boom {
  _Boom(this.x, this.y);

  final double x;
  final double y;
  double t = 0;
}

class _Arena {
  double w = 400;
  double h = 400;
  double pitW = 64;
  double platTop = 250;
  double gapL = 168;
  double gapR = 232;

  void layout(double newW, double newH) {
    w = newW;
    h = newH;
    pitW = math.max(48, w * 0.16);
    platTop = h * 0.8;
    gapL = w / 2 - pitW / 2;
    gapR = w / 2 + pitW / 2;
  }
}

class _StickmanDuelScreenState extends State<StickmanDuelScreen>
    with SingleTickerProviderStateMixin {
  final _Arena _arena = _Arena();
  final List<_Fighter> _f = [_Fighter(1), _Fighter(2)];
  final List<_Shot> _shots = [];
  final List<_Boom> _booms = [];
  late final Ticker _ticker;

  _Phase _phase = _Phase.weaponSelect;
  bool _two = false;
  int _diff = 1;
  int _score1 = 0;
  int _score2 = 0;
  bool _win = false;
  double _phaseT = 0;
  Duration? _last;
  final List<double> _upT = [0.0, 0.0];
  final List<bool> _upHeld = [false, false];

  _Fighter get _p1 => _f[0];
  _Fighter get _p2 => _f[1];

  static const double _kGravity = 1500;
  static const int _winRounds = 3;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _two = Prefs.effectiveTwoPlayer('stickman_duel');
    _diff = Prefs.difficultyFor('stickman_duel');
    _startRound();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  // ---------------------------------------------------------------- phases

  void _launch(int player, _Weapon w) {
    final f = _f[player - 1];
    f.weapon = w;
    f.launched = true;
    if (_p1.launched && _p2.launched) {
      _phase = _Phase.ready;
      _phaseT = 0;
    }
    setState(() {});
  }

  void _startRound() {
    for (final f in _f) {
      f.vx = 0;
      f.vy = 0;
      f.rot = 0;
      f.vrot = 0;
      f.grounded = true;
      f.dead = false;
      f.rld = 0;
      f.lungeVx = 0;
      f.attackT = -1;
      f.hurtT = 0;
      f.walk = 0;
      f.moveL = false;
      f.moveR = false;
      f.x = f.player == 1 ? _arena.gapL * 0.35 : _arena.w - _arena.gapR * 0.35;
      f.y = _arena.platTop;
      f.facing = 1;
    }
    _shots.clear();
    _booms.clear();
  }

  void _endRound(int winner) {
    if (winner == 1) {
      _score1++;
    } else {
      _score2++;
    }
    if (_score1 >= _winRounds || _score2 >= _winRounds) {
      _win = _score1 > _score2;
      _phase = _Phase.matchOver;
      _showResult();
      return;
    }
    _phase = _Phase.roundOver;
    _phaseT = 0;
    setState(() {});
  }

  void _showResult() {
    if (!mounted) return;
    final title = _two
        ? (_win ? 'Player 1 wins!' : 'Player 2 wins!')
        : (_win ? 'You win!' : 'You lose!');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ResultScreen(
          type: _win ? ResultType.win : ResultType.lose,
          title: title,
          subtitle:
              'Score ${math.max(_score1, _score2)}–${math.min(_score1, _score2)}',
          bestScore: _score1,
          gameId: 'stickman_duel',
          onReplay: _restartMatch,
          onHub: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      ),
    );
  }

  void _restartMatch() {
    _score1 = 0;
    _score2 = 0;
    _phase = _Phase.weaponSelect;
    for (final f in _f) {
      f.launched = false;
      f.dead = false;
    }
    _startRound();
    setState(() {});
  }

  // ------------------------------------------------------------------ loop

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final last = _last;
    _last = elapsed;
    final step = math.min(
        (last == null ? 0 : (elapsed - last).inMicroseconds) / 1e6, 0.05);

    // keep grounded feet glued to the slab top (orientation-safe)
    final ap = _arena.platTop;
    for (final f in _f) {
      if (f.grounded && f.vy == 0) f.y = ap;
    }

    switch (_phase) {
      case _Phase.weaponSelect:
        // bot picks its weapon shortly after the human picks theirs
        if (!_two && !_p2.launched && _p1.launched) {
          _p2.poc += step;
          if (_p2.poc > 0.5) {
            _launch(2, _botWeapon(_diff));
            _p2.poc = 0;
          }
        }
        break;
      case _Phase.ready:
        _phaseT += step;
        if (_phaseT > 0.9) {
          _phase = _Phase.fight;
        }
        break;
      case _Phase.fight:
        _sim(step);
        break;
      case _Phase.roundOver:
        _phaseT += step;
        if (_phaseT > 1.6) {
          _startRound();
          _phase = _Phase.fight;
        }
        break;
      case _Phase.matchOver:
        break;
    }
    setState(() {});
  }

  _Weapon _botWeapon(int diff) {
    final pool = diff == 2
        ? const [_Weapon.sword, _Weapon.gun, _Weapon.bat, _Weapon.bomb]
        : _Weapon.values;
    return pool[math.Random().nextInt(pool.length)];
  }

  // ------------------------------------------------------------- simulation

  void _sim(double dt) {
    final a = _arena;
    for (final f in _f) {
      f.rld = math.max(0, f.rld - dt);
      f.attackT -= dt;
      f.hurtT = math.max(0, f.hurtT - dt);
      if (f.dead) {
        // ragdoll: keep falling with gravity + spin until off screen
        f.y += f.vy * dt;
        f.vy += _kGravity * dt;
        f.x += f.vx * dt;
        f.vx *= (1 - 0.4 * dt);
        f.rot += f.vrot * dt;
        f.vrot *= (1 - 0.8 * dt);
        continue;
      }

      // --- hold the joystick UP ~3s to jump ---
      final pi = f.player - 1;
      if (_upHeld[pi] && f.grounded) {
        _upT[pi] += dt;
        if (_upT[pi] >= 3.0) {
          _upT[pi] = 0;
          _jump(f);
        }
      } else {
        _upT[pi] = 0;
      }

      // --- grounded fighter ---
      if (f.grounded) {
        double move = 0;
        if (f.moveL) move -= 1;
        if (f.moveR) move += 1;

        // integrate knockback + lunge + walk
        f.x += (f.vx + f.lungeVx) * dt + move * 240 * dt;
        f.walk += ((move.abs() * 240 + f.vx.abs()) / 240) * dt * 6;

        // hop (small bounce from a hit) then land back
        if (f.vy != 0) {
          f.y += f.vy * dt;
          f.vy += _kGravity * dt;
          if (f.y >= a.platTop) {
            f.y = a.platTop;
            f.vy = 0;
          }
        }

        // platform bounds — walking stops at the edge, knockback goes over
        final lo = f.player == 1 ? 12.0 : a.gapR + 12;
        final hi = f.player == 1 ? a.gapL - 12 : a.w - 12;
        final push = f.vx + f.lungeVx;
        if (f.x < lo) {
          if (f.player == 2 && push < 0) {
            f.grounded = false; // knocked past the left edge -> pit
          } else {
            f.x = lo;
          }
        } else if (f.x > hi) {
          if (f.player == 1 && push > 0) {
            f.grounded = false; // knocked past the right edge -> pit
          } else {
            f.x = hi;
          }
        }
        f.vx *= (1 - 2.5 * dt);
        f.lungeVx *= (1 - 3.2 * dt);

        // settle spin
        f.rot *= (1 - 4 * dt);
        if (f.rot.abs() < 0.01) f.rot = 0;
      } else {
        // --- airborne / falling into the pit ---
        f.y += f.vy * dt;
        f.vy += _kGravity * dt;
        f.x += f.vx * dt;
        f.vx *= (1 - 0.35 * dt);
        f.rot += f.vrot * dt;
        f.vrot *= (1 - 1.4 * dt);
        if (f.y > a.platTop + 20) {
          f.dead = true;
          _endRound(f.player == 1 ? 2 : 1);
          return;
        }
      }
    }

    if (!_two) _simBot(dt);

    // melee contact — touching the rival's blade hurts YOU
    for (final f in _f) {
      if (f.dead || !f.grounded) continue;
      final w = f.weapon;
      if (w != _Weapon.knife && w != _Weapon.sword && w != _Weapon.bat) {
        continue;
      }
      final foe = _f[f.player == 1 ? 1 : 0];
      if (foe.dead || foe.hurtT > 0) continue;
      final reach = switch (w) {
        _Weapon.knife => 56.0,
        _Weapon.sword => 72.0,
        _ => 84.0, // bat
      };
      final dx = foe.x - (f.x + f.facing * 12);
      if (dx.abs() > reach * 0.75 || (foe.y - f.y).abs() > 40) continue;
      foe.hurtT = 1.1;
      final impulse = switch (w) {
        _Weapon.knife => 540.0,
        _Weapon.sword => 660.0,
        _ => 820.0,
      };
      _applyHit(foe, foe.x >= f.x ? 1.0 : -1.0, impulse);
    }

    // projectiles
    for (final s in List<_Shot>.from(_shots)) {
      s.x += s.vx * dt;
      s.y += s.vy * dt;
      if (s.kind == 2) {
        s.vy += _kGravity * 0.62 * dt;
        s.fuse -= dt;
      }
      final target = _f[s.owner == 1 ? 1 : 0];
      final dx = s.x - target.x;
      final dy = s.y - (target.y - 30);
      final close = dx.abs() < 30 && dy.abs() < 60;
      if (s.kind == 2 && (s.fuse <= 0 || close)) {
        _explode(s.x, s.y);
        _shots.remove(s);
        continue;
      }
      if (s.kind != 2 && close) {
        _applyHit(target, s.owner == 1 ? 1.0 : -1.0, s.kind == 0 ? 360 : 280);
        _shots.remove(s);
        continue;
      }
      if (s.x < -40 || s.x > a.w + 40 || s.y > a.h + 40) {
        _shots.remove(s);
      }
    }

    for (final b in List<_Boom>.from(_booms)) {
      b.t += dt;
      if (b.t > 0.35) _booms.remove(b);
    }
  }

  void _applyHit(_Fighter foe, double dir, double impulse) {
    foe.vx += dir * impulse;
    foe.vy = -130;
    foe.vrot = dir * 2.6;
    foe.rot = dir * 0.4;
  }

  void _explode(double x, double y) {
    _booms.add(_Boom(x, y));
    for (final f in _f) {
      if (f.dead) continue;
      final dx = f.x - x;
      final dy = (f.y - 30) - y;
      final d = math.sqrt(dx * dx + dy * dy);
      if (d < 140) {
        final pull = 1 - d / 140;
        final dir = dx == 0 ? (f.player == 1 ? 1.0 : -1.0) : dx.sign.toDouble();
        f.vx += dir * 850 * pull;
        f.vy -= 320 * pull;
        f.vrot += dir * 4 * pull;
      }
    }
  }

  void _attack(_Fighter f) {
    if (f.dead || !f.grounded || f.rld > 0 || _phase != _Phase.fight) return;
    final w = f.weapon;
    switch (w) {
      // melee never fires — the blade itself is the weapon (contact damage)
      case _Weapon.knife:
      case _Weapon.sword:
      case _Weapon.bat:
        return;
      case _Weapon.bow:
        f.attackT = 0.3;
        f.rld = 1.1;
        _shots.add(
            _Shot(f.x + f.facing * 26, f.y - 46, f.facing * 620.0, 0, f.player, 1));
        break;
      case _Weapon.gun:
        f.attackT = 0.18;
        f.rld = 1.3;
        _shots.add(
            _Shot(f.x + f.facing * 28, f.y - 46, f.facing * 1050.0, 0, f.player, 0));
        break;
      case _Weapon.bomb:
        f.attackT = 0.26;
        f.rld = 2.2;
        _shots.add(_Shot(f.x + f.facing * 20, f.y - 58, f.facing * 340.0, -540,
            f.player, 2));
        break;
    }
  }

  /// Simple bot: approach until in range, attack; ranged keeps distance.
  void _simBot(double dt) {
    final bot = _p2;
    if (bot.dead || !bot.grounded) return;
    final foe = _p1;
    final dx = foe.x - bot.x;
    bot.thinkT -= dt;
    if (bot.thinkT > 0) return;
    bot.thinkT = switch (_diff) {
      0 => 0.8,
      1 => 0.5,
      _ => 0.3,
    };

    final isRanged =
        bot.weapon == _Weapon.bow || bot.weapon == _Weapon.gun ||
        bot.weapon == _Weapon.bomb;
    final range = isRanged ? 300.0 : 8.0;
    if (dx.abs() > range) {
      bot.facing = dx > 0 ? 1 : -1;
      bot.moveL = dx < 0;
      bot.moveR = dx > 0;
    } else {
      bot.moveL = false;
      bot.moveR = false;
      bot.facing = dx > 0 ? 1 : -1;
      final p = switch (_diff) {
        0 => 0.55,
        1 => 0.75,
        _ => 0.9,
      };
      if (math.Random().nextDouble() < p) _attack(bot);
    }
  }

  // ------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Stickman Fight',
      body: Column(
        children: [
          Expanded(
            child: CustomPaint(
              painter: _ArenaPainter(
                arena: _arena,
                fighters: _f,
                shots: _shots,
                booms: _booms,
                phase: _phase,
                score1: _score1,
                score2: _score2,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          if (_phase == _Phase.weaponSelect) _weaponPicker() else _controls(),
        ],
      ),
    );
  }

  Widget _controls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: _two
          ? Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _joy(1, _p1),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _joy(2, _p2),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                _joy(1, _p1),
                const Spacer(),
                const Text(
                  '▲ hold to jump\nrelease to fire',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: AppColors.subtext,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _joy(int player, _Fighter f) {
    return _Joystick(
      tag: 'P$player-JOY',
      charge: _upT[player - 1] / 3,
      onMove: (dx, dy) => _stick(player, dx, dy),
      onRelease: () => _attack(f),
    );
  }

  void _stick(int player, double dx, double dy) {
    final f = _f[player - 1];
    if (f.dead) return;
    f.moveL = dx < -0.25;
    f.moveR = dx > 0.25;
    _upHeld[player - 1] = dy < -0.55;
  }

  void _jump(_Fighter f) {
    if (f.dead || !f.grounded || _phase != _Phase.fight) return;
    f.vy = -540;
  }

  // ------------------------------------------------------ weapon select UI

  Widget _weaponPicker() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      color: AppColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _two ? 'Pick a weapon — P1 left, P2 right' : 'Pick your weapon',
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _pickerSide(1)),
              if (_two) ...[
                const SizedBox(width: 10),
                Expanded(child: _pickerSide(2)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _pickerSide(int player) {
    final f = _f[player - 1];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          player == 1 ? 'P1' : 'P2',
          style: TextStyle(
            color: player == 1 ? AppColors.gameBlue : AppColors.gameRed,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final w in _Weapon.values)
              InkWell(
                key: ValueKey('wep-$player-${w.name}'),
                onTap: f.launched ? null : () => _launch(player, w),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: f.launched && f.weapon == w
                        ? AppColors.accentDark
                        : AppColors.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: f.launched && f.weapon == w
                          ? AppColors.accent
                          : AppColors.cardBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(w.glyph, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      Text(
                        w.label,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}


// ============================================================== joystick

class _Joystick extends StatefulWidget {
  const _Joystick({
    required this.tag,
    required this.onMove,
    required this.onRelease,
    this.charge = 0,
  });

  final String tag;
  final void Function(double dx, double dy) onMove;
  final VoidCallback onRelease;
  final double charge; // 0..1 jump-charge progress (▲ hold)

  @override
  State<_Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<_Joystick> {
  static const double _r = 34; // base radius
  Offset _knob = Offset.zero;
  bool _active = false;

  void _drag(Offset local) {
    var d = local - const Offset(_r, _r);
    if (d.distance > _r) d = d / d.distance * _r;
    _active = true;
    setState(() => _knob = d);
    widget.onMove(d.dx / _r, d.dy / _r);
  }

  void _release() {
    if (!_active) return;
    _active = false;
    setState(() => _knob = Offset.zero);
    widget.onMove(0, 0);
    widget.onRelease();
  }

  @override
  Widget build(BuildContext context) {
    final charge = widget.charge.clamp(0.0, 1.0).toDouble();
    return GestureDetector(
      key: ValueKey(widget.tag),
      onPanStart: (e) => _drag(e.localPosition),
      onPanUpdate: (e) => _drag(e.localPosition),
      onPanEnd: (_) => _release(),
      onPanCancel: _release,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: _r * 2,
        height: _r * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.card,
          border: Border.all(color: AppColors.cardBorder, width: 2),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ▲ hint — hold up to jump
            const Positioned(
              top: 5,
              child: Text(
                '▲',
                style: TextStyle(
                  color: AppColors.subtext,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            // jump-charge arc: fills over ~3s of holding up
            SizedBox(
              width: _r * 2,
              height: _r * 2,
              child: CustomPaint(painter: _ChargeArcPainter(charge)),
            ),
            Transform.translate(
              offset: _knob,
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gameAmber,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChargeArcPainter extends CustomPainter {
  const _ChargeArcPainter(this.charge);

  final double charge;

  @override
  void paint(Canvas canvas, Size size) {
    if (charge <= 0.01) return;
    canvas.drawArc(
      (Offset.zero & size).deflate(4),
      -math.pi / 2,
      2 * math.pi * charge,
      false,
      Paint()
        ..color = AppColors.gameAmber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ChargeArcPainter old) =>
      old.charge != charge;
}

// ================================================================= paint

class _ArenaPainter extends CustomPainter {
  _ArenaPainter({
    required this.arena,
    required this.fighters,
    required this.shots,
    required this.booms,
    required this.phase,
    required this.score1,
    required this.score2,
  });

  final _Arena arena;
  final List<_Fighter> fighters;
  final List<_Shot> shots;
  final List<_Boom> booms;
  final _Phase phase;
  final int score1;
  final int score2;

  static const double _legH = 26;
  static const double _torso = 26;
  static const double _headR = 9;

  @override
  void paint(Canvas canvas, Size size) {
    arena.layout(size.width, size.height);
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.bg);
    _paintArena(canvas);
    _paintShots(canvas);
    for (final f in fighters) {
      if (!f.dead) _paintFighter(canvas, f);
    }
    _paintHud(canvas, size);
  }

  void _paintArena(Canvas canvas) {
    final platPaint = Paint()..color = AppColors.surface;
    final topPaint = Paint()
      ..color = AppColors.cardBorder
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final gT = arena.platTop;
    // horizontal ground slabs (thin) — the duel reads side-to-side
    canvas.drawRect(Rect.fromLTRB(0, gT, arena.gapL, gT + 22), platPaint);
    canvas.drawRect(Rect.fromLTRB(arena.gapR, gT, arena.w, gT + 22), platPaint);
    // pit: void below the gap
    canvas.drawRect(Rect.fromLTRB(arena.gapL, gT, arena.gapR, arena.h),
        Paint()..color = AppColors.bg);

    // pit spikes
    final spike = Paint()..color = AppColors.gameRed;
    const n = 6;
    for (var i = 0; i < n; i++) {
      final cx = arena.gapL + (i + 0.5) * (arena.pitW / n);
      final path = Path()
        ..moveTo(cx - 7, arena.platTop + 2)
        ..lineTo(cx, arena.platTop - 14)
        ..lineTo(cx + 7, arena.platTop + 2)
        ..close();
      canvas.drawPath(path, spike);
    }
    canvas.drawLine(
        Offset(0, arena.platTop), Offset(arena.gapL, arena.platTop), topPaint);
    canvas.drawLine(
        Offset(arena.gapR, arena.platTop), Offset(arena.w, arena.platTop), topPaint);
  }

  void _paintFighter(Canvas canvas, _Fighter f) {
    final color = f.player == 1 ? AppColors.gameBlue : AppColors.gameRed;
    final body = Paint()
      ..color = color
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.save();
    canvas.translate(f.x, f.y);
    canvas.rotate(f.rot);
    canvas.scale(f.facing.toDouble(), 1);

    final air = !f.grounded;
    final swing = math.sin(f.walk) * 0.5;
    final legA = air ? 0.95 : 0.35 + swing;
    final legB = air ? -0.95 : -0.35 + swing;

    // legs
    final hip = Offset(0, -_torso);
    canvas.drawLine(
        hip, Offset(math.sin(legA) * 16, hip.dy + _legH), body);
    canvas.drawLine(
        hip, Offset(math.sin(legB) * 16, hip.dy + _legH), body);

    // torso
    final neck = Offset(0, -_torso - 14);
    canvas.drawLine(hip, neck, body);

    // head
    canvas.drawCircle(
      Offset(0, -_torso - 14 - _headR),
      _headR,
      Paint()..color = color..style = PaintingStyle.fill,
    );

    // arms + weapon, driven by the attack animation
    final shoulder = Offset(0, -_torso - 10);
    final st = math.max(0.0, f.attackT);
    final back = -0.4 - st * 14;
    final fore = 0.4 + st * 14;
    final backHand = Offset(math.sin(back) * 20, shoulder.dy + math.cos(back) * 14);
    final foreHand = Offset(math.sin(fore) * 20, shoulder.dy + math.cos(fore) * 14);
    canvas.drawLine(shoulder, backHand, body);
    canvas.drawLine(shoulder, foreHand, body);
    _drawWeaponHand(canvas, f, foreHand);

    canvas.restore();
  }

  void _drawWeaponHand(Canvas canvas, _Fighter f, Offset hand) {
    final paint = Paint()
      ..color = AppColors.text
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    switch (f.weapon) {
      case _Weapon.knife:
        canvas.drawLine(hand, hand + Offset(18, 4), paint);
        break;
      case _Weapon.sword:
        paint.strokeWidth = 3.5;
        canvas.drawLine(hand, hand + Offset(30, -2), paint);
        break;
      case _Weapon.bat:
        paint.strokeWidth = 7;
        canvas.drawLine(hand, hand + Offset(26, -4), paint);
        break;
      case _Weapon.bow:
        canvas.drawArc(
            Rect.fromCircle(center: hand, radius: 16), -0.9, 1.8, false, paint);
        canvas.drawLine(
            hand + Offset(-10, -10),
            hand + Offset(10, 8),
            Paint()
              ..color = AppColors.subtext
              ..strokeWidth = 1.2);
        break;
      case _Weapon.gun:
        canvas.drawRect(
            Rect.fromLTWH(hand.dx, hand.dy - 3, 14, 6),
            Paint()..color = AppColors.text);
        break;
      case _Weapon.bomb:
        canvas.drawCircle(hand, 7, Paint()..color = AppColors.accent);
        break;
    }
  }

  void _paintShots(Canvas canvas) {
    for (final s in shots) {
      switch (s.kind) {
        case 0: // bullet
          canvas.drawCircle(
              Offset(s.x, s.y), 5, Paint()..color = AppColors.gameAmber);
          break;
        case 1: // arrow
          canvas.drawLine(
              Offset(s.x, s.y),
              Offset(s.x - s.vx.sign * 16, s.y),
              Paint()
                ..color = AppColors.text
                ..strokeWidth = 3);
          break;
        case 2: // bomb
          canvas.drawCircle(Offset(s.x, s.y), 8, Paint()..color = AppColors.bg);
          canvas.drawCircle(
              Offset(s.x, s.y), 8, Paint()..color = AppColors.text..style = PaintingStyle.stroke);
          break;
      }
    }
    for (final b in booms) {
      final k = 1 - b.t / 0.35;
      canvas.drawCircle(
        Offset(b.x, b.y),
        26 + b.t * 150,
        Paint()
          ..color = AppColors.gameRed.withOpacity(k * 0.55)
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _paintHud(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(
        text: 'P1  $score1',
        style: const TextStyle(
            color: AppColors.gameBlue, fontSize: 15, fontWeight: FontWeight.w800),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(14, 10));

    final tp2 = TextPainter(
      text: TextSpan(
        text: '$score2  P2',
        style: const TextStyle(
            color: AppColors.gameRed, fontSize: 15, fontWeight: FontWeight.w800),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp2.paint(canvas, Offset(size.width - tp2.width - 14, 10));

    String? banner;
    if (phase == _Phase.roundOver) {
      banner = score1 > score2 ? 'P1 takes the round!' : 'P2 takes the round!';
    } else if (phase == _Phase.ready) {
      banner = 'Fight!';
    }
    if (banner != null) {
      final b = TextPainter(
        text: TextSpan(
          text: banner,
          style: const TextStyle(
              color: AppColors.text, fontSize: 24, fontWeight: FontWeight.w900),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      b.paint(canvas, Offset((size.width - b.width) / 2, size.height * 0.3));
    }
  }

  @override
  bool shouldRepaint(covariant _ArenaPainter oldDelegate) => true;
}