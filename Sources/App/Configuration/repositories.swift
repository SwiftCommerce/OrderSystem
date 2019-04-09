import Service

func repositories(services: inout Services)throws {
    services.register(AddressRepository.self, factory: SCAddressRepository.makeService(for:))
}
