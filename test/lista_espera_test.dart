import 'package:app_eventos/Convite.dart';
import 'package:app_eventos/Evento.dart';
import 'package:app_eventos/ListaEspera.dart';
import 'package:app_eventos/convidado.dart';
import 'package:app_eventos/vagas_evento.dart';
import 'package:test/test.dart';

Evento _evento({int? limite}) => Evento(
      idBanco: 1,
      nomeEvento: 'Festa',
      dataEvento: DateTime(2026, 12, 1),
      descricao: 'teste',
      tipodeevento: 'Casamento',
      limiteConvidados: limite,
    );

Convidado _pessoa(int id) =>
    Convidado(idBanco: id, nome: 'Pessoa $id', email: 'p$id@x.com');

List<Convite> _convites(Evento e, int quantos, {int recusados = 0}) => [
      for (int i = 0; i < quantos; i++)
        Convite(
          idBanco: i + 1,
          evento: e,
          convidado: _pessoa(100 + i),
          status: i < recusados ? StatusConfirmacao.recusado : StatusConfirmacao.confirmado,
        ),
    ];

void main() {
  group('VagasEvento (cálculo feito no código)', () {
    test('sem limite: não há vagas livres nem lotação', () {
      final e = _evento();
      final v = VagasEvento.calcular(e, _convites(e, 5), []);
      expect(v.temLimite, false);
      expect(v.vagasLivres, null);
      expect(v.lotado, false);
    });

    test('limite 10 com 7 convites: sobram 3 vagas', () {
      final e = _evento(limite: 10);
      final v = VagasEvento.calcular(e, _convites(e, 7), []);
      expect(v.convitesAtivos, 7);
      expect(v.vagasLivres, 3);
      expect(v.lotado, false);
    });

    test('convite recusado não ocupa vaga', () {
      final e = _evento(limite: 5);
      final v = VagasEvento.calcular(e, _convites(e, 5, recusados: 2), []);
      expect(v.convitesAtivos, 3);
      expect(v.vagasLivres, 2);
    });

    test('limite cheio: evento lotado', () {
      final e = _evento(limite: 3);
      expect(VagasEvento.calcular(e, _convites(e, 3), []).lotado, true);
    });

    test('limite menor que os convites: vagas ficam em 0, nunca negativas', () {
      final e = _evento(limite: 2);
      expect(VagasEvento.calcular(e, _convites(e, 4), []).vagasLivres, 0);
    });

    test('aumentar o limite abre vagas na hora', () {
      final e = _evento(limite: 3);
      final convites = _convites(e, 3);
      expect(VagasEvento.calcular(e, convites, []).lotado, true);
      e.limiteConvidados = 5;
      expect(VagasEvento.calcular(e, convites, []).vagasLivres, 2);
    });

    test('cabemDaFila é o menor entre vagas livres e tamanho da fila', () {
      final e = _evento(limite: 10);
      final fila = [
        for (int i = 1; i <= 4; i++)
          ItemListaEspera(evento: e, convidado: _pessoa(i), posicao: i),
      ];
      expect(VagasEvento.calcular(e, _convites(e, 8), fila).cabemDaFila, 2);
      expect(VagasEvento.calcular(e, _convites(e, 1), fila).cabemDaFila, 4);
    });

    test('convites de outro evento não contam', () {
      final e = _evento(limite: 3);
      final outro = Evento(
        idBanco: 2,
        nomeEvento: 'Outro',
        dataEvento: DateTime(2026, 12, 2),
        descricao: '',
        tipodeevento: 'Casamento',
      );
      final v = VagasEvento.calcular(e, _convites(outro, 3), []);
      expect(v.convitesAtivos, 0);
    });
  });

  group('Validações', () {
    test('limite 0 ou negativo é recusado pelo setter', () {
      final e = _evento();
      expect(() => e.limiteConvidados = 0, throwsArgumentError);
      expect(() => e.limiteConvidados = -5, throwsArgumentError);
    });

    test('limite null volta a ser "sem limite"', () {
      final e = _evento(limite: 10);
      e.limiteConvidados = null;
      expect(e.limiteConvidados, null);
    });

    test('posição na fila começa em 1', () {
      expect(
        () => ItemListaEspera(evento: _evento(), convidado: _pessoa(1), posicao: 0),
        throwsArgumentError,
      );
    });

    test('obterDados (polimorfismo do Registro) mostra posição e nome', () {
      final item = ItemListaEspera(evento: _evento(), convidado: _pessoa(7), posicao: 2);
      expect(item.obterDados(), contains('2º'));
      expect(item.toString(), contains('Pessoa 7'));
    });
  });
}
