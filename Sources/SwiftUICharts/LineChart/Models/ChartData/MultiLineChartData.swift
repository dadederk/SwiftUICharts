//
//  MultiLineChartData.swift
//  
//
//  Created by Will Dale on 24/01/2021.
//

import SwiftUI

/**
 Data for drawing and styling a multi line, line chart.
 
 This model contains all the data and styling information for a single line, line chart.
 
 # Example
 ```
 static func weekOfData() -> MultiLineChartData {
  
      let data = MultiLineDataSet(dataSets: [
                       LineDataSet(dataPoints: [
                           LineChartDataPoint(value: 60,  xAxisLabel: "M", pointLabel: "Monday"),
                           LineChartDataPoint(value: 90,  xAxisLabel: "T", pointLabel: "Tuesday"),
                           LineChartDataPoint(value: 100, xAxisLabel: "W", pointLabel: "Wednesday"),
                           LineChartDataPoint(value: 75,  xAxisLabel: "T", pointLabel: "Thursday"),
                           LineChartDataPoint(value: 160, xAxisLabel: "F", pointLabel: "Friday"),
                           LineChartDataPoint(value: 110, xAxisLabel: "S", pointLabel: "Saturday"),
                           LineChartDataPoint(value: 90,  xAxisLabel: "S", pointLabel: "Sunday")
                       ],
                       legendTitle: "Test One",
                       pointStyle: PointStyle(),
                       style: LineStyle(colour: Color.red)),
                       LineDataSet(dataPoints: [
                           LineChartDataPoint(value: 90,  xAxisLabel: "M", pointLabel: "Monday"),
                           LineChartDataPoint(value: 60,  xAxisLabel: "T", pointLabel: "Tuesday"),
                           LineChartDataPoint(value: 120, xAxisLabel: "W", pointLabel: "Wednesday"),
                           LineChartDataPoint(value: 85,  xAxisLabel: "T", pointLabel: "Thursday"),
                           LineChartDataPoint(value: 140, xAxisLabel: "F", pointLabel: "Friday"),
                           LineChartDataPoint(value: 80,  xAxisLabel: "S", pointLabel: "Saturday"),
                           LineChartDataPoint(value: 50,  xAxisLabel: "S", pointLabel: "Sunday")
                       ],
                       legendTitle: "Test Two",
                       pointStyle: PointStyle(),
                       style: LineStyle(colour: Color.blue))])
      
      return MultiLineChartData(dataSets: data,
                                metadata: ChartMetadata(title: "Some Data", subtitle: "A Week"),
                                xAxisLabels: ["Monday", "Thursday", "Sunday"],
                                chartStyle: LineChartStyle(infoBoxPlacement: .fixed,
                                                           markerType: .full(attachment: .line(dot: .style(DotStyle()))),
                                                           baseline: .minimumWithMaximum(of: 40)))
  }
 ```
 */
public final class MultiLineChartData: CTLineChartDataProtocol {

    // MARK: Properties
    public let id   : UUID = UUID()
    
    @Published public final var dataSets      : MultiLineDataSet
    @Published public final var metadata      : ChartMetadata
    @Published public final var xAxisLabels   : [String]?
    @Published public final var chartStyle    : LineChartStyle
    @Published public final var legends       : [LegendData]
    @Published public final var viewData      : ChartViewData
    @Published public final var infoView      : InfoViewData<LineChartDataPoint> = InfoViewData()
    
    public final var noDataText   : Text
    public final var chartType    : (chartType: ChartType, dataSetType: DataSetType)
    
    internal final var isFilled      : Bool = false
    
    // MARK: Initializers
    /// Initialises a Multi Line Chart.
    ///
    /// - Parameters:
    ///   - dataSets: Data to draw and style the lines.
    ///   - metadata: Data model containing the charts Title, Subtitle and the Title for Legend.
    ///   - xAxisLabels: Labels for the X axis instead of the labels in the data points.
    ///   - chartStyle: The style data for the aesthetic of the chart.
    ///   - noDataText: Customisable Text to display when where is not enough data to draw the chart.
    public init(dataSets    : MultiLineDataSet,
                metadata    : ChartMetadata     = ChartMetadata(),
                xAxisLabels : [String]?         = nil,
                chartStyle  : LineChartStyle    = LineChartStyle(),
                noDataText  : Text              = Text("No Data")
    ) {
        self.dataSets       = dataSets
        self.metadata       = metadata
        self.xAxisLabels    = xAxisLabels
        self.chartStyle     = chartStyle
        self.noDataText     = noDataText
        self.legends        = [LegendData]()
        self.viewData       = ChartViewData()
        self.chartType      = (.line, .multi)
        self.setupLegends()
    }

    // MARK: Labels
    public final func getXAxisLabels() -> some View {
        Group {
            switch self.chartStyle.xAxisLabelsFrom {
            case .dataPoint:
                
                HStack(spacing: 0) {
                    ForEach(dataSets.dataSets[0].dataPoints) { data in
                        if let label = data.xAxisLabel {
                            Text(label)
                                .font(.caption)
                                .foregroundColor(self.chartStyle.xAxisLabelColour)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .accessibilityLabel(Text("X Axis Label"))
                                .accessibilityValue(Text("\(data.wrappedXAxisLabel)"))
                        }
                        if data != self.dataSets.dataSets[0].dataPoints[self.dataSets.dataSets[0].dataPoints.count - 1] {
                            Spacer()
                                .frame(minWidth: 0, maxWidth: 500)
                        }
                    }
                }
                .padding(.horizontal, -4)
                
                
            case .chartData:
                if let labelArray = self.xAxisLabels {
                    HStack(spacing: 0) {
                        ForEach(labelArray, id: \.self) { data in
                            Text(data)
                                .font(.caption)
                                .foregroundColor(self.chartStyle.xAxisLabelColour)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .accessibilityLabel(Text("X Axis Label"))
                                .accessibilityValue(Text("\(data)"))
                            if data != labelArray[labelArray.count - 1] {
                                Spacer()
                                    .frame(minWidth: 0, maxWidth: 500)
                            }
                        }
                    }
                    .padding(.horizontal, -4)
                }
            }
        }
    }
    
    // MARK: Points
    public final func getPointMarker() -> some View {
        ForEach(self.dataSets.dataSets, id: \.id) { dataSet in
            PointsSubView(dataSets  : dataSet,
                          minValue  : self.minValue,
                          range     : self.range,
                          animation : self.chartStyle.globalAnimation,
                          isFilled  : self.isFilled)
        }
    }

    public final func getTouchInteraction(touchLocation: CGPoint, chartSize: CGRect) -> some View {
       ZStack {
            ForEach(self.dataSets.dataSets, id: \.id) { dataSet in
                self.markerSubView(dataSet: dataSet,
                                   dataPoints: dataSet.dataPoints,
                                   lineType: dataSet.style.lineType,
                                   touchLocation: touchLocation,
                                   chartSize: chartSize)
            }
        }
    }
    
    // MARK: Accessibility
    public func getAccessibility() -> some View {
      ForEach(self.dataSets.dataSets, id: \.self) { dataSet in
            ForEach(dataSet.dataPoints.indices, id: \.self) { point in
                AccessibilityRectangle(dataPointCount : dataSet.dataPoints.count,
                                       dataPointNo    : point)
                    .foregroundColor(Color(.gray).opacity(0.000000001))
                    .accessibilityLabel(Text("\(self.metadata.title)"))
                    .accessibilityValue(dataSet.dataPoints[point].getCellAccessibilityValue(specifier: self.infoView.touchSpecifier))
            }
        }
    }
    
    public typealias Set = MultiLineDataSet
    public typealias DataPoint = LineChartDataPoint
    public typealias CTStyle = LineChartStyle
}


// MARK: - Touch
extension MultiLineChartData {
    public func getPointLocation(dataSet: LineDataSet, touchLocation: CGPoint, chartSize: CGRect) -> CGPoint? {
        
        let minValue : Double = self.minValue
        let range    : Double = self.range
        
        let xSection : CGFloat = chartSize.width / CGFloat(dataSet.dataPoints.count - 1)
        let ySection : CGFloat = chartSize.height / CGFloat(range)
        
        let index    : Int     = Int((touchLocation.x + (xSection / 2)) / xSection)
        if index >= 0 && index < dataSet.dataPoints.count {
            return CGPoint(x: CGFloat(index) * xSection,
                           y: (CGFloat(dataSet.dataPoints[index].value - minValue) * -ySection) + chartSize.height)
        }
        return nil
    }
    public func getDataPoint(touchLocation: CGPoint, chartSize: CGRect) {
        var points : [LineChartDataPoint] = []
        for dataSet in dataSets.dataSets {
            let xSection    : CGFloat = chartSize.width / CGFloat(dataSet.dataPoints.count - 1)
            let index       = Int((touchLocation.x + (xSection / 2)) / xSection)
            if index >= 0 && index < dataSet.dataPoints.count {
                points.append(dataSet.dataPoints[index])
            }
        }
        self.infoView.touchOverlayInfo = points
    }
}
