import Foundation
import Home
import MEGADomain
import MEGAPreference
import MEGAPreferenceMocks
import Testing

@Suite("HomeWidget config resilience")
struct HomeWidgetConfigResilienceTests {

    // MARK: - Safely decoded (removing widget types)

    @Suite("HomeWidgetConfigEntity.safelyDecodedWidgetConfigs")
    struct SafelyDecodedWidgetConfigsTests {

        @Test("drops entries with unknown widget type and keeps valid ones")
        func dropsUnknownKeepsValid() throws {
            // Simulate stored JSON that contains a widget type no longer in the enum
            let json = """
            [
                {"type":"shortcuts","isEnabled":true},
                {"type":"deletedWidget","isEnabled":false},
                {"type":"recents","isEnabled":false}
            ]
            """
            let data = try #require(json.data(using: .utf8))

            let result = try #require(HomeWidgetConfigEntity.safelyDecodedWidgetConfigs(from: data))

            #expect(result.count == 2)
            #expect(result[0] == HomeWidgetConfigEntity(type: .shortcuts, isEnabled: true))
            #expect(result[1] == HomeWidgetConfigEntity(type: .recents, isEnabled: false))
        }

        @Test("returns nil when all entries are unknown")
        func returnsNilWhenAllUnknown() throws {
            let json = """
            [
                {"type":"deletedA","isEnabled":true},
                {"type":"deletedB","isEnabled":false}
            ]
            """
            let data = try #require(json.data(using: .utf8))

            #expect(HomeWidgetConfigEntity.safelyDecodedWidgetConfigs(from: data) == nil)
        }

        @Test("returns nil for invalid JSON")
        func returnsNilForInvalidJSON() throws {
            let data = try #require("not json".data(using: .utf8))
            #expect(HomeWidgetConfigEntity.safelyDecodedWidgetConfigs(from: data) == nil)
        }

        @Test("decodes all valid entries normally")
        func decodesAllValid() throws {
            let configs = [
                HomeWidgetConfigEntity(type: .shortcuts, isEnabled: true),
                HomeWidgetConfigEntity(type: .recents, isEnabled: false)
            ]
            let data = try JSONEncoder().encode(configs)

            let result = try #require(HomeWidgetConfigEntity.safelyDecodedWidgetConfigs(from: data))

            #expect(result == configs)
        }
    }

    // MARK: - Syncing new widget types (adding)

    @Suite("HomeWidgetDisplayUseCase syncs new widget types")
    struct DisplayUseCaseSyncTests {

        @Test("includes new widget types not present in stored configs")
        func includesNewWidgetTypes() throws {
            // Store only a subset of widget types
            let partialConfigs: [HomeWidgetConfigEntity] = [
                .init(type: .shortcuts, isEnabled: true),
                .init(type: .accountDetails, isEnabled: true)
            ]
            let data = try JSONEncoder().encode(partialConfigs)
            let prefUseCase = MockPreferenceUseCase(dict: [
                PreferenceKeyEntity.homeWidgetConfigs.rawValue: data
            ])
            let sut = HomeWidgetDisplayUseCase(preferenceUseCase: prefUseCase)

            let result = sut.allVisibleWidgetTypes()

            // All HomeWidgetType cases should be represented
            for widgetType in HomeWidgetType.allCases {
                #expect(result.contains(widgetType), "Missing widget type: \(widgetType)")
            }
        }
    }

    // MARK: - Combined: unknown + missing

    @Suite("Combined resilience")
    struct CombinedTests {

        @Test("handles both unknown stored types and missing new types")
        func handlesUnknownAndMissing() throws {
            // JSON with only "shortcuts" valid, plus an unknown type
            let json = """
            [
                {"type":"shortcuts","isEnabled":true},
                {"type":"deletedWidget","isEnabled":false}
            ]
            """
            let data = try #require(json.data(using: .utf8))
            let prefUseCase = MockPreferenceUseCase(dict: [
                PreferenceKeyEntity.homeWidgetConfigs.rawValue: data
            ])
            let sut = HomeWidgetDisplayUseCase(preferenceUseCase: prefUseCase)

            let result = sut.allVisibleWidgetTypes()

            // "deletedWidget" should be gone, all current types should be present
            for widgetType in HomeWidgetType.allCases {
                #expect(result.contains(widgetType), "Missing widget type: \(widgetType)")
            }
        }
    }
}
