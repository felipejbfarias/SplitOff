import Foundation
import SwiftData

@Model
final class Transferencia {
    var id: UUID = UUID()
    var valor: Decimal
    var data: Date
    var tipo: String
    var observacao: String?
    var pagadorNome: String
    var recebedorNome: String

    var tipoTransferencia: TipoTransferencia {
        get { TipoTransferencia(rawValue: tipo) ?? .quitacao }
        set { tipo = newValue.rawValue }
    }

    var grupo: Grupo?

    @Relationship(deleteRule: .nullify)
    var pagador: Pessoa?

    @Relationship(deleteRule: .nullify)
    var recebedor: Pessoa?

    init(
        valor: Decimal,
        data: Date = Date.now,
        tipo: TipoTransferencia = .quitacao,
        observacao: String? = nil,
        grupo: Grupo? = nil,
        pagador: Pessoa? = nil,
        recebedor: Pessoa? = nil,
        pagadorNome: String? = nil,
        recebedorNome: String? = nil
    ) {
        self.valor = valor
        self.data = data
        self.tipo = tipo.rawValue
        self.observacao = observacao
        self.grupo = grupo
        self.pagador = pagador
        self.recebedor = recebedor
        self.pagadorNome = pagadorNome ?? pagador?.nome ?? ""
        self.recebedorNome = recebedorNome ?? recebedor?.nome ?? ""
    }
}
