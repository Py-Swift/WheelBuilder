//
//  WheelsToBuild.swift
//  WheelBuilder
//
import CiWheels
import Foundation
import PyPi_Api

public enum WheelsToBuild: String, Decodable {
    case aiohttp
    case apsw
}

public enum AnacondaPackages: String, CaseIterable {
    case aiohttp
    case apsw
    case argon2_cffi = "argon2-cffi"
    case backports_zoneinfo = "backports-zoneinfo"
    case bcrypt
    case bitarray
    case brotli
    case bzip2
    case cffi
    case contourpy
    case coverage
    case cryptography
    case cymem
    case cytoolz
    case editdistance
    case ephem
    case freetype
    case frozenlist
    case gensim
    case greenlet
//    case ios
//    case kivy
//    case kivy_sdl2 = "kivy-sdl2"
//    case kivy_sdl3_angle = "kivy-sdl3-angle"
    case kiwisolver
    case libffi
    case libjpeg
    case libpng
    case lru_dict = "lru-dict"
    case lxml
    case materialyoucolor
    case matplotlib
    case msgpack
    case multidict
    case murmurhash
    case netifaces
    case ninja
    case numpy
    case openssl
    case orjson
    case pandas
    case pendulum
    //case pillow
    case preshed
    case pycrypto
    case pycryptodome
    case pycurl
    case pydantic_core = "pydantic-core"
    case pymunk
    case pyzmq
    case pynacl
    case pyobjus
    case pysha3
    case pywavelets
    case pyzbar
    case regex
    case ruamel_yaml_clib = "ruamel-yaml-clib"
    case scandir
    case spectrum
    case sqlalchemy
    case srsly
    case statsmodels
    case twisted
    case typed_ast = "typed-ast"
    case ujson
    case wordcloud
    case xz
    case yarl
    case zeroconf
}

extension AnacondaPackages {
    
    public var baseURL: URL? {
        URL(string: "https://api.anaconda.org/package/pyswift/\(rawValue)")
    }
    
    public var wheel_package: (any WheelProtocol.Type)? {
        switch self {
        case .aiohttp: CiWheels.Aiohttp.self
        case .apsw: CiWheels.Apsw.self
        case .argon2_cffi: nil
        case .backports_zoneinfo: nil
        case .bcrypt: nil
        case .bitarray: CiWheels.Bitarray.self
        case .brotli: nil
        case .bzip2: nil
        case .cffi: CiWheels.Cffi.self
        case .contourpy: CiWheels.Contourpy.self
        case .coverage: CiWheels.Coverage.self
        case .cryptography: CiWheels.Cryptography.self
        case .cymem: nil
        case .cytoolz: nil
        case .editdistance: nil
        case .ephem: nil
        case .freetype: nil
        case .frozenlist: nil
        case .gensim: nil
        case .greenlet: CiWheels.Greenlet.self
//        case .ios: nil
//        case .kivy: nil
//        case .kivy_sdl2: nil
//        case .kivy_sdl3_angle: nil
        case .kiwisolver: CiWheels.Kiwisolver.self
        case .libffi: nil//CiWheels.Libffi.self
        case .libjpeg: nil
        case .libpng: nil
        case .lru_dict: nil
        case .lxml: nil
        case .materialyoucolor: CiWheels.Materialyoucolor.self
        case .matplotlib: CiWheels.Matplotlib.self
        case .msgpack: CiWheels.Msgpack.self
        case .multidict: nil
        case .murmurhash: nil
        case .netifaces: CiWheels.Netifaces.self
        case .ninja: nil
        case .numpy: CiWheels.Numpy.self
        case .openssl: nil
        case .orjson: CiWheels.Orjson.self
        case .pandas: nil//CiWheels.Pandas.self
        case .pendulum: CiWheels.Pendulum.self
//        case .pillow: nil
        case .preshed: nil
        case .pycrypto: nil
        case .pycryptodome: CiWheels.Pycryptodome.self
        case .pycurl: nil
        case .pydantic_core: CiWheels.Pydantic_core.self
        case .pymunk: CiWheels.Pymunk.self
        case .pyzmq: CiWheels.Pyzmq.self
        case .pynacl: nil
        case .pyobjus: nil
        case .pysha3: nil
        case .pywavelets: nil
        case .pyzbar: nil
        case .regex: nil
        case .ruamel_yaml_clib: nil
        case .scandir: nil
        case .spectrum: nil
        case .sqlalchemy: CiWheels.SQLAlchemy.self
        case .srsly: nil
        case .statsmodels: nil
        case .twisted: nil
        case .typed_ast: nil
        case .ujson: nil//CiWheels.Ujson.self
        case .wordcloud: nil
        case .xz: nil
        case .yarl: nil
        case .zeroconf: CiWheels.Zeroconf.self
        }
    }
    
    func packageData() async throws -> Data {
        guard let baseURL else { fatalError() }
        let request = URLRequest(url: baseURL)
        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }
    public func packageData() async throws -> IphoneosWheelSources.PackageData {
        try JSONDecoder().decode(
            IphoneosWheelSources.PackageData.self,
            from: try await packageData()
        )
    }
}


