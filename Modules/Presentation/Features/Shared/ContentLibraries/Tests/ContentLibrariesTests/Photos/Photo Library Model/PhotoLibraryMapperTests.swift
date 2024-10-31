@testable import ContentLibraries
import MEGADomain
import MEGAFoundation
import XCTest

private extension Date {
    var year: Date {
        get throws { try XCTUnwrap(removeMonth(timeZone: .GMT)) }
    }
    
    var month: Date {
        get throws { try XCTUnwrap(removeDay(timeZone: .GMT)) }
    }
    
    var day: Date {
        get throws { try XCTUnwrap(removeTimestamp(timeZone: .GMT)) }
    }
}

class PhotoLibraryMapperTests: XCTestCase {
    var nodes = [NodeEntity]()
    
    override func setUpWithError() throws {
        nodes = [
            NodeEntity(name: "a.jpg", handle: 0, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 2, modificationTime: try "2022-07-18T22:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 3, modificationTime: try "2022-04-18T22:01:04Z".date),
            NodeEntity(name: "d.mp4", handle: 4, modificationTime: try "2021-08-18T22:01:04Z".date),
            NodeEntity(name: "e.jpg", handle: 5, modificationTime: try "2021-01-18T22:01:04Z".date),
            NodeEntity(name: "f.jpg", handle: 6, modificationTime: try "2020-12-18T22:01:04Z".date),
            NodeEntity(name: "g.jpg", handle: 7, modificationTime: try "2020-10-18T22:01:04Z".date),
            NodeEntity(name: "h.jpg", handle: 8, modificationTime: try "2020-10-15T22:01:04Z".date),
            NodeEntity(name: "i.jpg", handle: 9, modificationTime: try "2018-09-18T22:01:04Z".date),
            NodeEntity(name: "j.jpg", handle: 10, modificationTime: try "2016-03-18T22:01:04Z".date),
            NodeEntity(name: "k.jpg", handle: 11, modificationTime: try "2016-03-18T20:01:04Z".date),
            NodeEntity(name: "l.jpg", handle: 12, modificationTime: try "2016-03-15T10:01:04Z".date),
            NodeEntity(name: "l.jpg", handle: 20, modificationTime: try "2016-03-15T10:01:04Z".date),
            NodeEntity(name: "l.jpg", handle: 13, modificationTime: try "2016-03-15T10:01:04Z".date),
            NodeEntity(name: "m.jpg", handle: 14, modificationTime: try "2015-04-13T17:15:00Z".date),
            NodeEntity(name: "o.jpg", handle: 15, modificationTime: try "2015-04-13T17:14:00Z".date),
            NodeEntity(name: "p.jpg", handle: 16, modificationTime: try "2015-04-13T17:12:00Z".date)
        ]
    }
    
    func testMapping_sort_oldest() throws {
        let photoLibrary = nodes.toPhotoLibrary(withSortType: .modificationAsc, in: .GMT)
        XCTAssertEqual(Set(photoLibrary.allPhotos), Set(nodes))
        XCTAssertEqual(photoLibrary.photoByYearList.count, 6)
        
        let expectedPhotoLibrary = PhotoLibrary(photoByYearList: [
            PhotoByYear(categoryDate: try "2015-01-01T00:00:00Z".date.year, contentList: [
                PhotoByMonth(categoryDate: try "2015-04-01T00:00:00Z".date.month, contentList: [
                    PhotoByDay(categoryDate: try "2015-04-13T17:12:00Z".date.day, contentList: [
                        NodeEntity(name: "p.jpg", handle: 16, modificationTime: try "2015-04-13T17:12:00Z".date),
                        NodeEntity(name: "o.jpg", handle: 15, modificationTime: try "2015-04-13T17:14:00Z".date),
                        NodeEntity(name: "m.jpg", handle: 14, modificationTime: try "2015-04-13T17:15:00Z".date)
                    ])
                ])
            ]),
            PhotoByYear(categoryDate: try "2016-03-01T00:00:00Z".date.year, contentList: [
                PhotoByMonth(categoryDate: try "2016-03-01T00:00:00Z".date.month, contentList: [
                    PhotoByDay(categoryDate: try "2016-03-15T10:01:04Z".date.day, contentList: [
                        NodeEntity(name: "l.jpg", handle: 20, modificationTime: try "2016-03-15T10:01:04Z".date),
                        NodeEntity(name: "l.jpg", handle: 13, modificationTime: try "2016-03-15T10:01:04Z".date),
                        NodeEntity(name: "l.jpg", handle: 12, modificationTime: try "2016-03-15T10:01:04Z".date)
                    ]),
                    PhotoByDay(categoryDate: try "2016-03-18T17:01:04Z".date.day, contentList: [
                        NodeEntity(name: "k.jpg", handle: 11, modificationTime: try "2016-03-18T20:01:04Z".date),
                        NodeEntity(name: "j.jpg", handle: 10, modificationTime: try "2016-03-18T22:01:04Z".date)
                    ])
                ])
            ]),
            PhotoByYear(categoryDate: try "2018-01-01T00:00:00Z".date.year, contentList: [
                PhotoByMonth(categoryDate: try "2018-09-01T00:00:00Z".date.month, contentList: [
                    PhotoByDay(categoryDate: try "2018-09-18T22:01:04Z".date.day, contentList: [
                        NodeEntity(name: "i.jpg", handle: 9, modificationTime: try "2018-09-18T22:01:04Z".date)
                    ])
                ])
            ]),
            PhotoByYear(categoryDate: try "2020-01-01T00:00:00Z".date.year, contentList: [
                PhotoByMonth(categoryDate: try "2020-10-01T00:00:00Z".date.month, contentList: [
                    PhotoByDay(categoryDate: try "2020-10-15T22:01:04Z".date.day, contentList: [
                        NodeEntity(name: "h.jpg", handle: 8, modificationTime: try "2020-10-15T22:01:04Z".date)
                    ]),
                    PhotoByDay(categoryDate: try "2020-10-18T22:01:04Z".date.day, contentList: [
                        NodeEntity(name: "g.jpg", handle: 7, modificationTime: try "2020-10-18T22:01:04Z".date)
                    ])
                ]),
                PhotoByMonth(categoryDate: try "2020-12-01T00:00:00Z".date.month, contentList: [
                    PhotoByDay(categoryDate: try "2020-12-18T22:01:04Z".date.day, contentList: [
                        NodeEntity(name: "f.jpg", handle: 6, modificationTime: try "2020-12-18T22:01:04Z".date)
                    ])
                ])
            ]),
            PhotoByYear(categoryDate: try "2021-01-01T00:00:00Z".date.year, contentList: [
                PhotoByMonth(categoryDate: try "2021-01-01T00:00:00Z".date.month, contentList: [
                    PhotoByDay(categoryDate: try "2021-01-18T22:01:04Z".date.day, contentList: [
                        NodeEntity(name: "e.jpg", handle: 5, modificationTime: try "2021-01-18T22:01:04Z".date)
                    ])
                ]),
                PhotoByMonth(categoryDate: try "2021-08-01T00:00:00Z".date.month, contentList: [
                    PhotoByDay(categoryDate: try "2021-08-18T22:01:04Z".date.day, contentList: [
                        NodeEntity(name: "d.mp4", handle: 4, modificationTime: try "2021-08-18T22:01:04Z".date)
                    ])
                ])
            ]),
            PhotoByYear(categoryDate: try "2022-01-01T00:00:00Z".date.year, contentList: [
                PhotoByMonth(categoryDate: try "2022-04-01T00:00:00Z".date.month, contentList: [
                    PhotoByDay(categoryDate: try "2022-04-18T22:01:04Z".date.day, contentList: [
                        NodeEntity(name: "c.mov", handle: 3, modificationTime: try "2022-04-18T22:01:04Z".date)
                    ])
                ]),
                PhotoByMonth(categoryDate: try "2022-07-01T00:00:00Z".date.month, contentList: [
                    PhotoByDay(categoryDate: try "2022-07-18T22:01:04Z".date.day, contentList: [
                        NodeEntity(name: "b.jpg", handle: 2, modificationTime: try "2022-07-18T22:01:04Z".date)
                    ])
                ]),
                PhotoByMonth(categoryDate: try "2022-08-01T00:00:00Z".date.month, contentList: [
                    PhotoByDay(categoryDate: try "2022-08-18T22:01:04Z".date.day, contentList: [
                        NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
                        NodeEntity(name: "a.jpg", handle: 0, modificationTime: try "2022-08-18T22:01:04Z".date)
                    ])
                ])
            ])
        ])
        
        XCTAssertEqual(photoLibrary, expectedPhotoLibrary)
    }
    
    func testMapping_sort_newest() throws {
        let photoLibrary = nodes.toPhotoLibrary(withSortType: .modificationDesc, in: .GMT)
        XCTAssertEqual(Set(photoLibrary.allPhotos), Set(nodes))
        XCTAssertEqual(photoLibrary.photoByYearList.count, 6)
        
        let expectedPhotoLibrary = PhotoLibrary(photoByYearList: [
            PhotoByYear(categoryDate: try "2022-01-01T00:00:00Z".date.year, contentList: [
                PhotoByMonth(categoryDate: try "2022-08-01T00:00:00Z".date.month, contentList: [
                    PhotoByDay(categoryDate: try "2022-08-18T22:01:04Z".date.day, contentList: [
                        NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
                        NodeEntity(name: "a.jpg", handle: 0, modificationTime: try "2022-08-18T22:01:04Z".date)
                    ])
                ]),
                PhotoByMonth(categoryDate: try "2022-07-01T00:00:00Z".date.month, contentList: [
                    PhotoByDay(categoryDate: try "2022-07-18T22:01:04Z".date.day, contentList: [
                        NodeEntity(name: "b.jpg", handle: 2, modificationTime: try "2022-07-18T22:01:04Z".date)
                    ])
                ]),
                PhotoByMonth(categoryDate: try "2022-04-01T00:00:00Z".date.month, contentList: [
                    PhotoByDay(categoryDate: try "2022-04-18T22:01:04Z".date.day, contentList: [
                        NodeEntity(name: "c.mov", handle: 3, modificationTime: try "2022-04-18T22:01:04Z".date)
                    ])
                ])
            ]),
            PhotoByYear(categoryDate: try "2021-01-01T00:00:00Z".date.year, contentList: [
                PhotoByMonth(categoryDate: try "2021-08-01T00:00:00Z".date.month, contentList: [
                    PhotoByDay(categoryDate: try "2021-08-18T22:01:04Z".date.day, contentList: [
                        NodeEntity(name: "d.mp4", handle: 4, modificationTime: try "2021-08-18T22:01:04Z".date)
                    ])
                ]),
                PhotoByMonth(categoryDate: try "2021-01-01T00:00:00Z".date.month, contentList: [
                    PhotoByDay(categoryDate: try "2021-01-18T22:01:04Z".date.day, contentList: [
                        NodeEntity(name: "e.jpg", handle: 5, modificationTime: try "2021-01-18T22:01:04Z".date)
                    ])
                ])
            ]),
            PhotoByYear(categoryDate: try "2020-01-01T00:00:00Z".date.year, contentList: [
                PhotoByMonth(categoryDate: try "2020-12-01T00:00:00Z".date.month, contentList: [
                    PhotoByDay(categoryDate: try "2020-12-18T22:01:04Z".date.day, contentList: [
                        NodeEntity(name: "f.jpg", handle: 6, modificationTime: try "2020-12-18T22:01:04Z".date)
                    ])
                ]),
                PhotoByMonth(categoryDate: try "2020-10-01T00:00:00Z".date.month, contentList: [
                    PhotoByDay(categoryDate: try "2020-10-18T22:01:04Z".date.day, contentList: [
                        NodeEntity(name: "g.jpg", handle: 7, modificationTime: try "2020-10-18T22:01:04Z".date)
                    ]),
                    PhotoByDay(categoryDate: try "2020-10-15T22:01:04Z".date.day, contentList: [
                        NodeEntity(name: "h.jpg", handle: 8, modificationTime: try "2020-10-15T22:01:04Z".date)
                    ])
                ])
            ]),
            PhotoByYear(categoryDate: try "2018-01-01T00:00:00Z".date.year, contentList: [
                PhotoByMonth(categoryDate: try "2018-09-01T00:00:00Z".date.month, contentList: [
                    PhotoByDay(categoryDate: try "2018-09-18T22:01:04Z".date.day, contentList: [
                        NodeEntity(name: "i.jpg", handle: 9, modificationTime: try "2018-09-18T22:01:04Z".date)
                    ])
                ])
            ]),
            PhotoByYear(categoryDate: try "2016-03-01T00:00:00Z".date.year, contentList: [
                PhotoByMonth(categoryDate: try "2016-03-01T00:00:00Z".date.month, contentList: [
                    PhotoByDay(categoryDate: try "2016-03-18T17:01:04Z".date.day, contentList: [
                        NodeEntity(name: "j.jpg", handle: 10, modificationTime: try "2016-03-18T22:01:04Z".date),
                        NodeEntity(name: "k.jpg", handle: 11, modificationTime: try "2016-03-18T20:01:04Z".date)
                    ]),
                    PhotoByDay(categoryDate: try "2016-03-15T10:01:04Z".date.day, contentList: [
                        NodeEntity(name: "l.jpg", handle: 20, modificationTime: try "2016-03-15T10:01:04Z".date),
                        NodeEntity(name: "l.jpg", handle: 13, modificationTime: try "2016-03-15T10:01:04Z".date),
                        NodeEntity(name: "l.jpg", handle: 12, modificationTime: try "2016-03-15T10:01:04Z".date)
                    ])
                ])
            ]),
            PhotoByYear(categoryDate: try "2015-01-01T00:00:00Z".date.year, contentList: [
                PhotoByMonth(categoryDate: try "2015-04-01T00:00:00Z".date.month, contentList: [
                    PhotoByDay(categoryDate: try "2015-04-13T17:12:00Z".date.day, contentList: [
                        NodeEntity(name: "m.jpg", handle: 14, modificationTime: try "2015-04-13T17:15:00Z".date),
                        NodeEntity(name: "o.jpg", handle: 15, modificationTime: try "2015-04-13T17:14:00Z".date),
                        NodeEntity(name: "p.jpg", handle: 16, modificationTime: try "2015-04-13T17:12:00Z".date)
                    ])
                ])
            ])
        ])
        
        XCTAssertEqual(photoLibrary, expectedPhotoLibrary)
    }
}
