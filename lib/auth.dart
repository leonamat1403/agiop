import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

// Autenticação LOCAL do protótipo: as contas ficam no SQLite do próprio aparelho/navegador.
// A senha nunca é guardada: só salt + PBKDF2-HMAC-SHA256.
// LIMITAÇÃO: sem servidor não há contas compartilhadas entre aparelhos nem recuperação de senha.

final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');
final _usuarioRe = RegExp(r'^[A-Za-z0-9._-]{3,20}$');

bool emailValido(String e) => _emailRe.hasMatch(e.trim());

/// 3 a 20 caracteres: letras, números, ponto, hífen ou sublinhado.
bool usuarioValido(String u) => _usuarioRe.hasMatch(u.trim());

const _iteracoes = 10000;

String novoSalt() {
  final r = Random.secure();
  return base64Url.encode(List<int>.generate(16, (_) => r.nextInt(256)));
}

String hashSenha(String senha, String salt) {
  final hmac = Hmac(sha256, utf8.encode(senha));
  var u = hmac.convert([...base64Url.decode(salt), 0, 0, 0, 1]).bytes;
  final t = List<int>.from(u);
  for (var i = 1; i < _iteracoes; i++) {
    u = hmac.convert(u).bytes;
    for (var j = 0; j < t.length; j++) {
      t[j] ^= u[j];
    }
  }
  return base64Url.encode(t);
}

bool verificarSenha(String senha, String salt, String hash) {
  final h = hashSenha(senha, salt);
  if (h.length != hash.length) return false;
  var d = 0;
  for (var i = 0; i < h.length; i++) {
    d |= h.codeUnitAt(i) ^ hash.codeUnitAt(i); // comparação sem atalho
  }
  return d == 0;
}
