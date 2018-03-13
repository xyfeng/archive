# Module
ios = require 'ios-kit'
makeGradient = require("makeGradient")
moment = require("npm").moment

## Global
white = '#fff'
darkBlue = '#4D4FFF'
lightPurple = '#D540FD'
brightGreen = '#15E9A9'
neonGreen = '#00F0E5'
grayBlue = '#21405C'

SHADOW_COLOR = 'rgba(0, 0, 0, 0.5)'

Framer.Defaults.Animation =
	curve: 'ease-in-out'
	time: 0.3

now = moment()

currScreen = null

# CSS
css = """
* {
	-webkit-font-smoothing: antialiased;
}

@font-face {
    font-family: TiemposMedium;
    font-weight: normal;
    src: url('fonts/Tiempos Headline-Medium.otf');
}
@font-face {
    font-family: CalibreRegular;
    font-weight: normal;
    src: url('fonts/Calibre-Regular.otf');
}
@font-face {
    font-family: CalibreMedium;
    font-weight: normal;
    src: url('fonts/Calibre-Medium.otf');
}
@font-face {
    font-family: CalibreSemiBold;
    font-weight: normal;
    src: url('fonts/Calibre-Semibold.otf');
}

h1,h2,h3,h4,h5,h6 {
	font-weight: normal;
}

#modal {
	padding: 30px 60px;
	text-align: center;
	color: #2D4B6C;
}

#modal h4 {
	font-family: CalibreSemiBold;
	font-size: 30px !important;
	letter-spacing: 6px;
	margin-top: 30px;
	margin-bottom: 100px;
}

#modal p {
	font-family: TiemposMedium;
	font-size: 36px;
	line-height: 48px;
}

.action-label span{
	font-size: 40px;
	font-family: CalibreSemiBold;
	display: block;
}

.card-index {
	position: absolute;
	right: 54px;
	top: 54px;
}

.table-item {
	height: 100px;
	padding-left: 96px;
}
.table-item .table-description {
	position: absolute;
	left: 304px;
	top: 40px;
	display: inline-block;
}

.section-header {
	height: 160px;
	display: block;
}
.section-header .section-title {
	font-family: CalibreRegular;
	font-size: 52px;
	text-align: center;
	padding-top: 38px;
}
.section-header .section-subtitle {
	position: absolute;
	font-family: CalibreRegular;
	font-size: 40px;
	text-align: right;
	top: 38px;
	right: 32px;
}
.section-list-item {
	margin: 0 32px;
	padding: 32px 0 16px 0;
	height: 40px;
	border-bottom: 1px solid rgba(255,255,255,0.5);
	font-size: 40px;
	line-height: 40px;
	font-family: CalibreRegular;
}
.section-list-item .factor {
	position: absolute;
}
.section-list-item .mgdl {
	position: absolute;
	left: 300px;
	width: 140px;
	text-align: center;
	font-family: CalibreSemiBold;
}
.section-list-item .duration {
	position: absolute;
	right: 32px;
}

.graph-label {
	color: #21405C;
	font-family: CalibreSemiBold;
	font-size: 26px;
	letter-spacing: 2px;
}


"""
Utils.insertCSS(css)

# Classes

class Curve
	constructor: (pts, ctx, sp, ep, g1, g2, c) ->
		# make a copy of pts
		@points = pts.slice()
		@context = ctx
		@startPts = sp
		@endPts = ep
		@gradientPt1 = g1
		@gradientPt2 = g2
		@color = Object.assign({}, c)

		@per = 1
		@opacity = 1
		@visible = true
		@fadeIn = false
		@fadeOut = false
		@dashedCurve = false
		@displayShadow = false
		@shadowColor = SHADOW_COLOR
		@borderLength = 10
		@targetColor = null
		return
	addTargetCurve: (t) ->
		@target = t
		if @target.length > @points.length
			lastPoint = @points[@points.length - 1]
			for i in [0..@target.length-@points.length-1]
				@points.push
					x: lastPoint.x
					y: lastPoint.y
		for i in [0..@points.length-1]
			pt = @points[i]
			if i < @target.length - 1
				pt.tx = t[i].x
				pt.ty = t[i].y
			else
				pt.tx = t[@target.length - 1].x
				pt.ty = t[@target.length - 1].y
		return
	addTargetColor: (c) ->
		@targetColor = Object.assign({}, c)
	update: ()->
		if @per < 0.8
			@per += (1 - @per) * 0.08
		else if @per < 1
			@per += 0.05
		else if @per != 1
			@per = 1

		if @fadeIn
			if @opacity < 0.99
				@opacity += (1 - @opacity) * 0.2
			else
				@opacity = 1
				@fadeIn = false

		if @fadeOut
			if @opacity > 0.01
				@opacity += (0 - @opacity) * 0.2
			else
				@opacity = 0
				@fadeOut = false

		if @targetColor != null
			if Math.abs(@targetColor.r - @color.r) + Math.abs(@targetColor.g - @color.g) + Math.abs(@targetColor.b - @color.b) > 6
				@color.r = Math.round(@color.r + (@targetColor.r - @color.r) * 0.2)
				@color.g = Math.round(@color.g + (@targetColor.g - @color.g) * 0.2)
				@color.b = Math.round(@color.b + (@targetColor.b- @color.b) * 0.2)
			else
				@color.r = @targetColor.r
				@color.g = @targetColor.g
				@color.b = @targetColor.b
				@targetColor = null

		if @per == 1 and @animateTarget and @target
			done = true
			for one in @points
				if Math.abs(one.x - one.tx) < 1
					one.x = one.tx
				else
					done = false
				if Math.abs(one.y - one.ty) < 1
					one.y = one.ty
				else
					done = false
				one.x += (one.tx - one.x) * 0.15
				one.y += (one.ty - one.y) * 0.15
			if done == true
				@animateTarget = false
	draw: ()->
		if not @visible
			return
		if @dashedCurve
			# do something
			@path = new Path2D()
			lastX = @per * (@points[@points.length-1].x - @points[0].x) + @points[0].x
			@path.moveTo @points[0].x, @points[0].y
			startY = @points[0].y
			index = 0
			for one in @points
				if one.x <= lastX && index % 10 == 0
					@path.lineTo one.x, one.y
				index++
			if @per != 1
				@path.lineTo lastX, startY
			@context.save()
			@context.lineWidth = 10
			@context.lineCap = 'butt'
			@context.lineJoin = 'bevel'
			@context.setLineDash([4,6])
			@context.strokeStyle = 'rgb(' + @color.r + ',' + @color.g + ',' + @color.b + ')'
			@context.stroke(@path)
			@context.restore()
		else
			@path = new Path2D()
			lastX = @per * (@points[@points.length-1].x - @points[0].x) + @points[0].x
			startY = null
			if @startPts != null
				@path.moveTo @startPts[0].x, @startPts[0].y
				startY = @startPts[0].y
				if @startPts.length > 1
					for i in [1..@startPts.length-1]
						one = @startPts[i]
						@path.lineTo one.x, one.y
			else
				@path.moveTo @points[0].x, @points[0].y
				startY = @points[0].y
			index = 0
			for one in @points
				if one.x <= lastX && index % 15 == 0
					@path.lineTo one.x, one.y
				index++
			if @per != 1
				@path.lineTo lastX, startY
			else if @endPts != null
				for one in @endPts
					@path.lineTo one.x, one.y
			@path.closePath()

			@context.save()
			if @displayShadow
				@context.shadowColor = @shadowColor
				@context.shadowY = -6
				@context.shadowBlur = 10
			# generate gradient
			cStr1 = 'rgba(' + @color.r + ',' + @color.g + ',' + @color.b + ',' + @opacity + ')'
			cStr2 = 'rgba(' + @color.r + ',' + @color.g + ',' + @color.b + ', 0)'
			gr = @context.createLinearGradient @gradientPt1.x, @gradientPt1.y, @gradientPt2.x, @gradientPt2.y
			gr.addColorStop 0, cStr1
			gr.addColorStop 1, cStr2
			@context.fillStyle = gr
			@context.fill(@path)
			@context.restore()
		return

# Functions

# get one point at each pixel
generatePointsFromArray = (arr) ->
	points = []
	for s in [0..(arr.length/2 - 1)/3-1]
		i = s * 3 * 2
		s =
			x: arr[i]
			y: arr[i+1]
		c1 =
			x: arr[i+2]
			y: arr[i+3]
		c2 =
			x: arr[i+4]
			y: arr[i+5]
		e =
			x: arr[i+6]
			y: arr[i+7]
		pts = generatePoints s, c1, c2, e, e.x - s.x
		points.push.apply(points, pts)
	return points

generatePoints = (s, c1, c2, e, n) ->
  points = []
  increments = 1 / n
  T = 0
  while T <= 1
    # plot a point on the curve
    pos = getCubicBezierXYatT(s, c1, c2, e, T)
    # calculate the tangent angle of the curve at that point
    tx = bezierTangent(s.x, c1.x, c2.x, e.x, T)
    ty = bezierTangent(s.y, c1.y, c2.y, e.y, T)
    a = Math.atan2(ty, tx) - (Math.PI / 2)
    # save the x/y position of the point and the tangent angle
    # in the points array
    points.push
      x: pos.x
      y: pos.y
      a: a
    T += increments
  return points

# calculate one XY point along Cubic Bezier at interval T
# (where T==0.00 at the start of the curve and T==1.00 at the end)
getCubicBezierXYatT = (startPt, controlPt1, controlPt2, endPt, T) ->
  x = CubicN(T, startPt.x, controlPt1.x, controlPt2.x, endPt.x)
  y = CubicN(T, startPt.y, controlPt1.y, controlPt2.y, endPt.y)
  return {
    x: x
    y: y
  }
CubicN = (T, a, b, c, d) ->
  t2 = T * T
  t3 = t2 * T
  return a + (-a * 3 + T * (3 * a - (a * T))) * T + (3 * b + T * (-6 * b + b * 3 * T)) * T + (c * 3 - (c * 3 * T)) * t2 + d * t3
# calculate the tangent angle at interval T on the curve
bezierTangent = (a, b, c, d, t) ->
  return 3 * t * t * (-a + 3 * b - (3 * c) + d) + 6 * t * (a - (2 * b) + c) + 3 * (-a + b)

## Functions
getOffsetPos = (event) ->
	rect = event.target.getBoundingClientRect()
	p =
		x: event.pageX - rect.left
		y: event.pageY - rect.top
	if event instanceof MouseEvent
		p =
			x: event.offsetX
			y: event.offsetY
	return p

# gradient background
updateBackground = ->
	# time of day
	tod = moment().hours()
	if tod >= 0 && tod < 6
		makeGradient.linear bgLayer, ["#33F9CC", "#2E36E7"]
		titleLabel.style.color = darkBlue
		dotBtn.image = 'images/actionDots2.png'
	else if tod >= 6 && tod < 12
		makeGradient.linear bgLayer, ["#F9E633", "#FF892E"]
		titleLabel.style.color = darkBlue
		dotBtn.image = 'images/actionDots2.png'
	else if tod >= 12 && tod < 18
		makeGradient.linear bgLayer, ["#2343DB", "#F96F33"]
		titleLabel.style.color = white
		dotBtn.image = 'images/actionDots1.png'
	else if tod >= 18
		makeGradient.linear bgLayer, ["#37CBFF", "#D72EE7"]
		titleLabel.style.color = white
		dotBtn.image = 'images/actionDots1.png'

setModalContent = (title, text, btn) ->
	for one in modal.children
		one.destroy()
	str = '<div id="modal"><h4>' + title + '</h4><p>' + text + '</p></div>'
	modal.html = str

createBtn = (_p, _x, _y, _w, _h, _img1, _img2, _event) ->
	btn = new Layer
		parent: _p
		x: _x
		y: _y
		width: _w
		height: _h
		image: _img1
	btn.defaultImagePath = _img1
	btn.pressedImagePath = _img2
	btn.on Events.TapStart, ()->
		btn.image = btn.pressedImagePath
	btn.on Events.TapEnd, ()->
		btn.image = btn.defaultImagePath
		_event()
	return btn

addFadeInOut = (l) ->
	l.popin = new Animation l,
		opacity: 1
	l.popout = new Animation l,
		opacity: 0

showSystemMenu = ->
	for one in modal.children
		one.destroy()
	setModalContent '', ''
	overlayLayer.placeBefore currScreen
	modal.placeBefore overlayLayer
	overlayLayer.fadein()
	modal.popin.start()

	createBtn modal, 140, 30, 410, 150, 'images/settingBtnLaunch.png', 'images/settingBtnLaunch.png', ()->
		modal.popout.start()
		Utils.delay 0.3, ()->
			overlayLayer.fadeout()
			hideLoadingScreen()
			hideMainScreen()
			hideCoverScreen()
			hideCalScreen()
			hideDiscoveryScreen()
			showLoadingScreen()

	createBtn modal, 140, 140, 410, 150, 'images/settingBtnHome.png', 'images/settingBtnHome.png', ()->
		modal.popout.start()
		Utils.delay 0.3, ()->
			overlayLayer.fadeout()
			hideLoadingScreen()
			hideMainScreen()
			hideCoverScreen()
			hideCalScreen()
			hideDiscoveryScreen()
			showMainScreen()

	createBtn modal, 140, 250, 410, 150, 'images/settingBtnDiscovery.png', 'images/settingBtnDiscovery.png', ()->
		modal.popout.start()
		Utils.delay 0.3, ()->
			overlayLayer.fadeout()
			hideLoadingScreen()
			hideMainScreen()
			hideCoverScreen()
			hideCalScreen()
			showDiscoveryScreen()

	createBtn modal, 140, 370, 410, 150, 'images/settingBtnCalculator.png', 'images/settingBtnCalculator.png', ()->
		modal.popout.start()
		Utils.delay 0.3, ()->
			overlayLayer.fadeout()
			hideLoadingScreen()
			hideMainScreen()
			hideCoverScreen()
			hideDiscoveryScreen()
			showCalScreen()

	createBtn modal, 140, 480, 410, 150, 'images/settingBtnCover.png', 'images/settingBtnCover', ()->
		modal.popout.start()
		Utils.delay 0.3, ()->
			overlayLayer.fadeout()
			hideLoadingScreen()
			hideMainScreen()
			hideCalScreen()
			hideDiscoveryScreen()
			showCoverScreen()

#Loading Screen

homeCanvasP5 = null

# Data
homeCurveData = [0, 318, 352, 538, 382, -16, 780, 214]
homeCurveTop = 156
homeCurveBottom = 374

showLoadingScreen = ->
	currScreen = loadLoadingScreen()

hideLoadingScreen = ->
	if homeCanvasP5
		homeCanvasP5.remove()
	currScreen.destroy()

loadLoadingScreen = () ->
	loadingScreen = new Layer
		width: 750
		height: 1334
		backgroundColor: "rgba(123,123,123,0)"

	homeScreen = new Layer
		parent: loadingScreen
		width: 750
		height: 1334
		image: "images/homeScreen.png"
	homeScreen.states.original =
		scale: 1
		opacity: 1
	homeScreen.states.stateA =
		scale: 2
		opacity: 0

	darkHomeBG = new Layer
		parent: loadingScreen
		width: 124
		height: 124
		image: "images/dardBG3.png"
		y: 1168
		x: 52
		opacity: 0
	darkHomeBG.states.original =
		y: 1168
		x: 52
		width: 124
		height: 124
		opacity: 0
	darkHomeBG.states.stateA =
		x: 0
		y: 0
		width: 750
		height: 1334
		opacity: 1

	homeWave = new Layer
		parent: darkHomeBG
		width: 750
		height: 780
		image: "images/homeWave.png"
		y: 554
	homeWave.states.original =
		opacity: 1
	homeWave.states.stateA =
		opacity: 0

	## Canvas Layer
	homeCanvas = new Layer
		parent: darkHomeBG
		html: '<div id="home_canvas"></div>'
		backgroundColor: "transparent"
		x: 0
		y: 554
		width: 750
		height: 780

	guruBtn = new Layer
		parent: loadingScreen
		x: 52
		y: 1168
		height: 124
		width: 124
		backgroundColor: "rgba(123,123,123,0)"

	homeWelcome = new Layer
		parent: darkHomeBG
		width: 432
		height: 202
		image: "images/homeWelcome.png"
		x: 154
		y: 140
	homeWelcome.states.original =
		opacity: 1
	homeWelcome.states.stateA =
		opacity: 0

	homeWelcomeBack = new Layer
		parent: darkHomeBG
		width: 654
		height: 64
		image: "images/homeWelcomeBack.png"
		x: 50
		y: -100
	homeWelcomeBack.states.original =
		y: -100
	homeWelcomeBack.states.stateA =
		y: 96

	homeSettingsBtn = new Layer
		parent: homeWelcomeBack
		x: 580
		width: 100
		height: 100
		opacity: 0.00
		y: -25

	homeMessage = new Layer
		parent: darkHomeBG
		width: 410
		height: 160
		image: "images/homeMessage.png"
		y: 354
		x: 170
		opacity: 0.00
	homeMessage.states.original =
		opacity: 0
	homeMessage.states.stateA =
		opacity: 1

	homeLogBtn = new Layer
		parent: darkHomeBG
		width: 392
		height: 124
		image: "images/homeLogBtn.png"
		y: 628
		x: 194
		opacity: 0.00
	homeLogBtn.states.original =
		opacity: 0
	homeLogBtn.states.stateA =
		opacity: 1

	homeDiscoveryBtn = new Layer
		parent: darkHomeBG
		width: 180
		height: 164
		image: "images/homeDiscoveryBtn.png"
		y: 1500
		x: 42
	homeDiscoveryBtn.states.original =
		y: 1500
	homeDiscoveryBtn.states.stateA =
		y: 1170

	# Canvas
	homeCanvasObj = (p)->
		p.reset = ->
			p.curve.points = generatePointsFromArray homeCurveData
			p.currFrame = 0
		p.setup = ->
			p.createCanvas(Screen.width, homeCanvas.height)
			p.frameRate = 30
			p.currFrame = 0

			homeCurvePts = generatePointsFromArray homeCurveData
			gradient1 =
				x: 0
				y: homeCurveTop
			gradient2 =
				x: 0
				y: homeCanvas.height
			color =
				r: 84
				g: 238
				b: 229
			startPts = [
				{
					x: 0
					y: homeCanvas.height
				}
			]
			endPts = [
				{
					x: homeCanvas.width
					y: homeCanvas.height
				}
			]
			p.curve = new Curve homeCurvePts, p.drawingContext, startPts, endPts, gradient1, gradient2, color
			p.curve.displayShadow = true
			p.curve.shadowColor = 'rgba(0,0,0,0.5)'
			p.curve.update()
			p.curve.draw()
			p.noLoop()
		p.draw = ->
			p.clear()
			array = homeCurveData.slice()
			for i in [0..3]
				sinSeed = p.currFrame
				sinHeight = Math.sin(sinSeed / 200) * 180
				if i == 0 or i == 3
					array[i*2 + 1] = (Math.cos(sinSeed / 200) - 0.5) * sinHeight + homeCurveData[i*2 + 1]
				else if i == 1
					array[i*2 + 1] = Math.sin(sinSeed / 200) * 2 * -sinHeight + homeCurveData[i*2 + 1]
				else
					array[i*2 + 1] = Math.sin(sinSeed / 200) * 2 * sinHeight + homeCurveData[i*2 + 1]
			p.curve.points = generatePointsFromArray array
			p.curve.update()
			p.curve.draw()
			p.currFrame++

	homeCanvasP5 = new p5(homeCanvasObj, 'home_canvas')

	# Events
	guruBtn.on Events.Tap, () ->
		guruBtn.visible = false
		launchGuru()
	homeSettingsBtn.on Events.Tap, ->
		showSystemMenu()

	# Functions
	launchGuru = ->
		homeScreen.animate 'stateA'
		darkHomeBG.animate 'stateA'

		Utils.delay 1, ->
			showWelcome()
			homeCanvasP5.loop()

	showWelcome = ->
		homeWelcome.animate 'stateA'
		homeWelcomeBack.animate 'stateA'
		homeMessage.animate 'stateA'
		homeLogBtn.animate 'stateA'
		homeDiscoveryBtn.animate 'stateA'
		homeWave.animate 'stateA'

	return loadingScreen




# Main Flow

showMainScreen = ->
	currScreen = loadMainScreen()

hideMainScreen = ->
# 	mainCanvasP5.noLoop()
	currScreen.destroy()

loadMainScreen = () ->
	# Data
	canvasY = 240
	canvasW = Screen.width
	canvasH = 520
	currPos =
		x: 88
		y: 6
	targetPos =
		x: 634
		y: 284

	curves = []
	currCurve = 0
	actionCurve = null
	curveData = [
		[currPos.x, currPos.y, 460, 10, 460, 244, targetPos.x, targetPos.y],
		[currPos.x, currPos.y, 360, 10, 320, 264, targetPos.x, targetPos.y],
		[currPos.x, currPos.y, 260, 10, 90, 284, targetPos.x, targetPos.y]
	]
	curvePoints = []

	gradientTop =
		x: 0
		y: 150
	gradientBottom =
		x: 0
		y: canvasH
	fillColor1 =
		r: 213
		g: 64
		b: 253
	fillColor2 =
		r: 77
		g: 79
		b: 255
	fillColor3 =
		r: 21
		g: 233
		b: 169
	startPts = [{
		x: 0
		y: canvasH
	},{
		x: 0
		y: 6
	}]
	endPts = [{
		x: canvasW
		y: 284
	},{
		x: canvasW
		y: canvasH
	}]
	mainScreen = new Layer
		width: 750
		height: 1334
		image: "images/dardBG3.png"

	mainBGText = new Layer
		parent: mainScreen
		width: 222
		height: 22
		image: "images/mainBGText.png"
		x: 264
		y: 188

	mainLabel = new Layer
		parent: mainScreen
		width: 480
		height: 50
		backgroundColor: 'transparent'
		x: Align.center
		y: 100
		html: 'Welcome Back'
		style:
			"font-family": "TiemposMedium"
			"font-size": "48px"
			"text-align": "center"

	mainSettingBtn = new Layer
		parent: mainScreen
		width: 60
		height: 60
		image: "images/mainSettingBtn.png"
		x: 652
		y: 80

	mainIOBGraph = new Layer
		parent: mainScreen
		width: 590
		height: 104
		x: 80
		y: 852
		image: "images/mainIOBGraph.png"
	addFadeInOut mainIOBGraph

	mainDiscoveryBtn = new Layer
		parent: mainScreen
		width: 180
		height: 164
		image: "images/homeDiscoveryBtn.png"
		y: 1170
		x: 42
	mainDiscoveryBtn.states.original =
		y: 1170
	mainDiscoveryBtn.states.stateA =
		y: 1500


	mainSettingsBtn = new Layer
		parent: mainScreen
		x: 632
		width: 100
		height: 100
		y: 60
		backgroundColor: 'transparent'

	mainGraphBG = new Layer
		parent: mainScreen
		width: 750
		height: 540
		y: 230
		image: "images/mainGraphBG.png"

	mainCanvas = new Layer
		parent: mainScreen
		html: '<div id="main_canvas"></div>'
		backgroundColor: "transparent"
		x: Align.center
		y: canvasY
		width: canvasW
		height: canvasH

	mainBGReading = new Layer
		parent: mainScreen
		width: 102
		height: 118
		image: "images/mainBGReading.png"
		x: currPos.x - 51
		y: 176

	currLabelText = new Layer
		parent: mainBGReading
		html: 'Now'
		width: 102
		backgroundColor: 'transparent'
		height: 25
		y: 145
		style:
			'font-family': 'CalibreRegular'
			'font-size': '40px'
			'text-align': 'center'

	targetLabel = new Layer
		parent: mainScreen
		x: targetPos.x - 58
		y: canvasY + targetPos.y - 58
		width: 116
		height: 116
		image: 'images/mainBGArrowDown.png'
		backgroundColor: '#FFF'
		style:
			borderRadius: '100%'
			overflow: 'hidden'
		shadowX: 10
		shadowY: 18
		shadowBlur: 16
		shadowColor: SHADOW_COLOR

	targetLabelText = new Layer
		parent: mainScreen
		html: '5:00 pm'
		backgroundColor: 'transparent'
		width: 128
		height: 25
		x: targetPos.x - 64
		y: canvasY + targetPos.y - 110
		style:
			'font-family': 'CalibreRegular'
			'font-size': '40px'
			'text-align': 'center'

	# Action Button
	actionSlowBtn = new Layer
		parent: mainScreen
		x: 466
		y: 706
		opacity: 0
		width: 116
		height: 116
		borderRadius: 100
		backgroundColor: "rgba(255,255,255,1)"
		html: '<div id="slow_btn"/>'
		shadowX: 5
		shadowY: 9
		shadowBlur: 8
		shadowColor: SHADOW_COLOR
	actionSlowBtn.popin = new Animation actionSlowBtn,
		opacity: 1
		options:
			time: 0.3
			curve: Bezier(0.25, 0.1, 0.25, 1)
	actionSlowBtn.popout = new Animation actionSlowBtn,
		opacity: 0
		options:
			time: 0.3
			curve: Bezier(0.25, 0.1, 0.25, 1)
	slowBlue = new Layer
		parent: actionSlowBtn
		width: 50
		height: 46
		image: "images/slowBlue.png"
		y: Align.center
		x: Align.center
	slowWhite = new Layer
		parent: actionSlowBtn
		width: 50
		height: 46
		image: "images/slowWhite.png"
		y: Align.center
		x: Align.center
		visible: false
	slowText = new Layer
		parent: actionSlowBtn
		backgroundColor: 'transparent'
		html: 'SLOW'
		width: 100
		height: 20
		x: 10
		y: -40
		style:
			'font-family': 'CalibreSemiBold'
			'font-size': '30px'
			'letter-spacing': '3px'
			'text-align': 'center'
	actionSlowBtn.on Events.Tap, ()->
		chooseAction 0
		return

	actionSteadyBtn = new Layer
		parent: mainScreen
		x: Screen.width / 2 - 58
		y: 706
		opacity: 0
		width: 116
		height: 116
		borderRadius: 100
		backgroundColor: "rgba(255,255,255,1)"
		shadowX: 5
		shadowY: 9
		shadowBlur: 8
		shadowColor: SHADOW_COLOR
	actionSteadyBtn.popin = new Animation actionSteadyBtn,
		opacity: 1
		options:
			time: 0.3
			delay: 0.1
			curve: Bezier(0.25, 0.1, 0.25, 1)
	actionSteadyBtn.popout = new Animation actionSteadyBtn,
		opacity: 0
		options:
			time: 0.3
			curve: Bezier(0.25, 0.1, 0.25, 1)
	steadyBlue = new Layer
		parent: actionSteadyBtn
		width: 46
		height: 46
		image: "images/steadyBlue.png"
		y: Align.center
		x: Align.center
	steadyWhite = new Layer
		parent: actionSteadyBtn
		width: 46
		height: 46
		image: "images/steadyWhite.png"
		y: Align.center
		x: Align.center
		visible: false
	steadyText = new Layer
		parent: actionSteadyBtn
		backgroundColor: 'transparent'
		html: 'STEADY'
		width: 100
		height: 20
		x: 0
		y: -40
		style:
			'font-family': 'CalibreSemiBold'
			'font-size': '30px'
			'letter-spacing': '3px'
			'text-align': 'center'
	actionSteadyBtn.on Events.Tap, ()->
		chooseAction 1
		return

	actionFastBtn = new Layer
		parent: mainScreen
		x: 174
		y: 706
		opacity: 0
		width: 116
		height: 116
		borderRadius: 100
		backgroundColor: "rgba(255,255,255,1)"
		shadowX: 5
		shadowY: 9
		shadowBlur: 8
		shadowColor: SHADOW_COLOR
	actionFastBtn.popin = new Animation actionFastBtn,
		opacity: 1
		options:
			time: 0.3
			delay: 0.2
			curve: Bezier(0.25, 0.1, 0.25, 1)
	actionFastBtn.popout = new Animation actionFastBtn,
		opacity: 0
		options:
			time: 0.3
			curve: Bezier(0.25, 0.1, 0.25, 1)
	fastBlue = new Layer
		parent: actionFastBtn
		width: 46
		height: 52
		image: "images/fastBlue.png"
		y: Align.center
		x: Align.center
	fastWhite = new Layer
		parent: actionFastBtn
		width: 46
		height: 52
		image: "images/fastWhite.png"
		y: Align.center
		x: Align.center
		visible: false
	fastText = new Layer
		parent: actionFastBtn
		backgroundColor: 'transparent'
		html: 'FAST'
		width: 100
		height: 20
		x: 10
		y: -40
		style:
			'font-family': 'CalibreSemiBold'
			'font-size': '30px'
			'letter-spacing': '3px'
			'text-align': 'center'
	actionFastBtn.on Events.Tap, ()->
		chooseAction 2
		return


	slowTable = new Layer
		parent: mainScreen
		width: 690
		height: 226
		image: "images/slowTable.png"
		x: 32
		y: 866
		opacity: 0
	addFadeInOut slowTable
	steadyTable = new Layer
		parent: mainScreen
		width: 690
		height: 226
		image: "images/steadyTable.png"
		x: 32
		y: 866
		opacity: 0
	addFadeInOut steadyTable
	fastTable = new Layer
		parent: mainScreen
		width: 690
		height: 226
		image: "images/fastTable.png"
		x: 32
		y: 866
		opacity: 0
	addFadeInOut fastTable

	expBtn = new Layer
		parent: mainScreen
		width: 264
		height: 44
		x: 240
		y: 1128
		image: "images/expBtnOff.png"
		opacity: 0
	expBtn.toggle = false
	addFadeInOut expBtn
	logBtn = new Layer
		parent: mainScreen
		width: 410
		height: 136
		image: "images/logBtn.png"
		x: Align.center
		y: 1198
		opacity: 0
	addFadeInOut logBtn

	## Actions Label
	actionNow = new Layer
		parent: mainScreen
		x: currPos.x
		y: canvasY + currPos.y
		width: 120
		height: canvasH
		backgroundColor: 'transparent'
	addFadeInOut actionNow
	actionNowText = new Layer
		parent: actionNow
		html: '<div class="action-label"><p>Activity<br>Now</p><span>15min<br>easy</span></div>'
		backgroundColor: 'transparent'
		width: 120
		height: 140
		x: -60
		y: 150
		opacity: 0
		style:
			'font-family': 'CalibreRegular'
			'font-size': '40px'
			'text-align': 'center'
			'line-height': '40px'
	actionNowText.popin = new Animation actionNowText,
		opacity: 1
		options:
			delay: 0.2
	actionNowLine = new Layer
		parent: actionNow
		y: 40
		height: 0
		width: 1
		backgroundColor: "transparent"
		borderWidth: 1
		style:
			'border-style': 'dashed'
			'border-color': '#fff'
			'border-top': 'none'
			'border-bottom': 'none'
	actionNowLine.popin = new Animation actionNowLine,
		height: 90
		options:
			time: 0.2
	actionNow.show = () ->
		actionNow.opacity = 0
		actionNowLine.height = 0
		actionNowLine.opacity = 1
		actionNowLine.popin.start()
		actionNowText.opacity = 0
		actionNowText.popin.start()

	action30 = new Layer
		parent: mainScreen
		x: currPos.x + 120
		y: canvasY + currPos.y
		width: 120
		height: canvasH
		backgroundColor: 'transparent'
	addFadeInOut action30
	action30Text = new Layer
		parent: action30
		html: '<div class="action-label"><p>Eat<br>+30 min</p><span>10g</span></div>'
		backgroundColor: 'transparent'
		width: 188
		height: 140
		x: -94
		y: 180
		opacity: 0
		style:
			'font-family': 'CalibreRegular'
			'font-size': '40px'
			'text-align': 'center'
			'line-height': '40px'
	action30Text.popin = new Animation action30Text,
		opacity: 1
		options:
			time: 0.3
			delay: 0.2
	action30Line = new Layer
		parent: action30
		width: 1
		height: 0
		y: 26
		backgroundColor: "transparent"
		borderWidth: 1
		style:
			'border-style': 'dashed'
			'border-color': '#fff'
			'border-top': 'none'
			'border-bottom': 'none'
	action30Line.popin = new Animation action30Line,
		height: 128
		options:
			time: 0.2
	action30.show = () ->
		action30.opacity = 1
		action30Line.height = 0
		action30Line.opacity = 1
		action30Text.opacity = 0
		Utils.delay 0.3, ->
			action30Line.popin.start()
			action30Text.popin.start()

	mainCanvasObj = (p)->
		p.reset = ->
			for one in curves
				one.per = 0
				one.points = generatePointsFromArray(curveData[1])
			curves[0].addTargetCurve curvePoints[0]
			curves[1].addTargetCurve curvePoints[1]
			curves[2].addTargetCurve curvePoints[2]
			actionCurve.visible = false

		p.setup = ->
			p.createCanvas(canvasW, canvasH)
			p.frameRate = 30
			# create curve points
			for one in curveData
				points = generatePointsFromArray one
				curvePoints.push points
			slowCurve = new Curve generatePointsFromArray(curveData[1]), p.drawingContext, startPts, endPts, gradientTop, gradientBottom, fillColor1
			slowCurve.addTargetCurve curvePoints[0]
# 			slowCurve.displayShadow = true
			slowCurve.per = 0
			curves.push slowCurve

			steadyCurve = new Curve generatePointsFromArray(curveData[1]), p.drawingContext, startPts, endPts, gradientTop, gradientBottom, fillColor2
			steadyCurve.per = 0
			steadyCurve.displayShadow = true
			curves.push steadyCurve

			fastCurve = new Curve generatePointsFromArray(curveData[1]), p.drawingContext, startPts, endPts, gradientTop, gradientBottom, fillColor3
			fastCurve.addTargetCurve curvePoints[2]
			fastCurve.displayShadow = true
			fastCurve.per = 0
			curves.push fastCurve

			actionCurve = new Curve generatePointsFromArray(curveData[0]), p.drawingContext, startPts, endPts, gradientTop, gradientBottom, fillColor1
			actionCurve.visible = false

		p.draw = ->
			p.clear()
			for one in curves
				one.update()
				one.draw()
			actionCurve.update()
			actionCurve.draw()

	mainCanvasP5 = new p5(mainCanvasObj, 'main_canvas')

	# Events

	mainSettingsBtn.on Events.Tap, ->
		mainCanvasP5.noLoop()
		showSystemMenu()

	targetLabel.on Events.Tap, ()->
		if targetLabel.state == 'actions'
			hideActions()
		else
			showActions()
			chooseAction 0

	showActions = ->
		targetLabel.state = 'actions'
		mainLabel.html = 'Choose Actions'
		mainBGText.visible = false
		currLabelText.visible = false

		# targe Btn
		targetLabel.image = 'images/mainBGClose.png'

		# action buttons
		actionSlowBtn.popin.start()
		actionSteadyBtn.popin.start()
		actionFastBtn.popin.start()

		# tasks
		mainIOBGraph.opacity = 0
		mainDiscoveryBtn.animate 'stateA'
		logBtn.popin.start()
		expBtn.popin.start()

		# curves
		for one in curves
			one.addTargetCurve curvePoints[0]
			one.animateTarget = true
			one.fadeOut = true
		actionCurve.opacity = 0
		actionCurve.visible = true
		actionCurve.fadeIn = true

		# actions time
		actionNow.show()

		return

	hideActions = ->
		targetLabel.state = 'default'
		mainLabel.html = 'Welcome Back'
		mainBGText.visible = true
		currLabelText.visible = true

		# targe Btn
		targetLabel.image = 'images/mainBGArrowDown.png'

		# curves
		curves[1].addTargetCurve curvePoints[1]
		curves[2].addTargetCurve curvePoints[2]
		for one in curves
			one.animateTarget = true
			one.fadeIn = true
		actionCurve.addTargetCurve curvePoints[2]
		actionCurve.animateTarget = true
		actionCurve.fadeOut = true

		# action buttons
		actionSlowBtn.popout.start()
		actionSteadyBtn.popout.start()
		actionFastBtn.popout.start()

		# tasks
		mainIOBGraph.popin.start()
		targetLabelText.html = "5:00 pm"
		mainDiscoveryBtn.animate 'original'
		logBtn.opacity = 0
		expBtn.opacity = 0

		slowTable.opacity = 0
		steadyTable.opacity = 0
		fastTable.opacity = 0

		# actions time
		actionNow.popout.start()
		action30.popout.start()
		return

	chooseAction = (i) ->
		currCurve = i
		if i == 0
			actionCurve.addTargetCurve curvePoints[0]
			actionCurve.addTargetColor fillColor1
			actionCurve.animateTarget = true

			actionSlowBtn.shadowColor = 'transparent'
			actionSlowBtn.backgroundColor = lightPurple
			slowBlue.visible = false
			slowWhite.visible = true

			actionSteadyBtn.backgroundColor = white
			steadyBlue.visible = true
			steadyWhite.visible = false
			actionFastBtn.backgroundColor = white
			fastBlue.visible = true
			fastWhite.visible = false

			slowTable.popin.start()
			steadyTable.popout.start()
			fastTable.popout.start()

			targetLabelText.html = "5:15 pm"
			actionNowText.html = '<div class="action-label"><p>Dose<br>Now</p><span>3u</span></div>'
			actionNow.popin.start()
			action30.opacity = 0
		else if i == 1
			actionCurve.addTargetCurve curvePoints[1]
			actionCurve.addTargetColor fillColor2
			actionCurve.animateTarget = true

			actionSteadyBtn.backgroundColor = darkBlue
			steadyBlue.visible = false
			steadyWhite.visible = true

			actionSlowBtn.backgroundColor = white
			slowBlue.visible = true
			slowWhite.visible = false
			actionFastBtn.backgroundColor = white
			fastBlue.visible = true
			fastWhite.visible = false

			slowTable.popout.start()
			steadyTable.popin.start()
			fastTable.popout.start()

			targetLabelText.html = "4:15 pm"
			actionNowText.html = '<div class="action-label"><p>Dose<br>Now</p><span>3u</span></div>'
			actionNow.popin.start()
			action30.show()
		else
			actionCurve.addTargetCurve curvePoints[2]
			actionCurve.addTargetColor fillColor3
			actionCurve.animateTarget = true

			actionFastBtn.backgroundColor = brightGreen
			fastBlue.visible = false
			fastWhite.visible = true

			actionSlowBtn.backgroundColor = white
			slowBlue.visible = true
			slowWhite.visible = false
			actionSteadyBtn.backgroundColor = white
			steadyBlue.visible = true
			steadyWhite.visible = false

			slowTable.popout.start()
			steadyTable.popout.start()
			fastTable.popin.start()

			targetLabelText.html = "3:15 pm"
			actionNowText.html = '<div class="action-label"><p>Activity<br>Now</p><span>15min<br>easy</span></div>'
			actionNow.popin.start()
			action30.opacity = 0
		return

	Utils.delay 0.6, ()->
		for one in curves
			one.animateTarget = true

	return mainScreen

# Cover Flow

showCoverScreen = ()->
	currScreen = loadCoverScreen()

hideCoverScreen = ()->
	currScreen.destroy()

loadCoverScreen = ()->
	# Data
	cards = []
	pageWidth = 698
	pageHeight = 644
	pageNumber = 3
	pageGap = 28
	pageOverlap = 85
	totalUnread = 3

	coverScreen = new Layer
		width: 750
		height: 1334
		image: "images/dardBG3.png"

	coverLabel = new Layer
		parent: coverScreen
		width: 480
		height: 50
		backgroundColor: 'transparent'
		x: Align.center
		y: 100
		html: 'Insights'
		style:
			"font-family": "TiemposMedium"
			"font-size": "48px"
			"text-align": "center"

	coverSettingBtn = new Layer
		parent: coverScreen
		width: 60
		height: 60
		image: "images/mainSettingBtn.png"
		x: 652
		y: 80

	coverSettingBtn.on Events.Tap, ()->
		showSystemMenu()


	coverDiscoveryBtn = new Layer
		parent: coverScreen
		width: 180
		height: 160
		image: "images/coverDiscoverBtn.png"
		y: 1170
		x: 42
	coverDiscoveryBtn.states.original =
		y: 1170
	coverDiscoveryBtn.states.stateA =
		y: 1500
	cardCounter = new Layer
		parent: coverScreen
		x: 137
		y: 1168
		width: 46
		height: 46
		borderRadius: '100%'
		backgroundColor: neonGreen
		html: totalUnread
		style:
			'font-family': 'CalibreSemiBold'
			'font-size': '40px'
			'line-height': '58px'
			'text-align': 'center'
			'color': grayBlue

	coverPage = new PageComponent
		parent: coverScreen
		width: 646
		height: 602
		x: Align.center
		y: 366
		scrollVertical: false
		clip: false
		backgroundColor: 'transparent'
	coverPage.animationOptions =
		time: 0.15
	coverPage.content.style.overflow = 'visible'

	for i in [0..pageNumber-1]
		card = new Layer
			y: 0
			width: coverPage.width
			height: coverPage.height
			backgroundColor: neonGreen
			shadowX: -8
			shadowY: 16
			shadowBlur: 22
			shadowColor: 'rgba(10, 60, 117, 0.2)'
			html: '<div class="card-index">' + (i+1) + '/' + pageNumber + '</div>'
			style:
				'border-bottom-left-radius': '100px'
				'font-family': 'CalibreSemiBold'
				'font-size': '30px'
				'letter-spacing': '5px'
				'color': grayBlue
		coverPage.addPage card
		card.x = i * (coverPage.width - pageOverlap)
		card.ci = i
		cards.push card

	# card 1
	new Layer
		parent: cards[0]
		width: 388
		height: 300
		image: "images/coverCard1.png"
		x: Align.center
		y: 54
	card1Cancel = new Layer
		parent: cards[0]
		width: 148
		height: 150
		image: "images/coverCancelBtn.png"
		x: 182
		y: 424
	card1Cancel.on Events.Tap, ->
		closeCard this.parent
	card1Ok = new Layer
		parent: cards[0]
		width: 148
		height: 150
		image: "images/coverOkBtn.png"
		x: 350
		y: 424
	card1Ok.on Events.Tap, ->
		closeCard this.parent

	new Layer
		parent: cards[1]
		width: 538
		height: 294
		image: "images/coverCard2.png"
		x: Align.center
		y: 54
	card1Cancel = new Layer
		parent: cards[1]
		width: 148
		height: 150
		image: "images/coverCancelBtn.png"
		x: 182
		y: 424
	card1Cancel.on Events.Tap, ->
		closeCard this.parent
	card2Ok = new Layer
		parent: cards[1]
		width: 148
		height: 150
		image: "images/coverOkBtn.png"
		x: 350
		y: 424
	card2Ok.on Events.Tap, ->
		closeCard this.parent

	new Layer
		parent: cards[2]
		width: 456
		height: 508
		image: "images/coverCard3.png"
		x: Align.center
		y: 54


	updatePages = ->
		for card in coverPage.content.children
			# Calculate what percentage of card is visible
			xRelativeToPage = card.x + coverPage.content.x
			xNotVisible = xRelativeToPage / coverPage.width
			visibleArea = Utils.modulate(Math.abs(xNotVisible), [0, 1], [1, 0], true)
			desiredScale = Utils.modulate(visibleArea, [1, 0], [1, 0.6])
			card.scale = desiredScale

	closeCard = (c) ->
		index = c.ci
		coverPage.scrollHorizontal = false
		cards[index].animate
			opacity: 0
			scale: 0.5
		Utils.delay 0.3, ->
			cards[index].destroy()
			cards.splice(index, 1)
			repositionCards()
			totalUnread--
			if totalUnread > 0
				cardCounter.html = totalUnread
			else
				cardCounter.visible = false
		Utils.delay 0.6, ->
			coverPage.scrollHorizontal = true

	repositionCards = =>
		currIndex = Math.abs(coverPage.content.x / (coverPage.width - pageOverlap))
		cardNumber = cards.length
		for card, i in cards
			card.ci = i
			card.html = '<div class="card-index">' + (i+1) + '/' + cardNumber + '</div>'
			if i == currIndex
				card.animate
					x: i * (coverPage.width - pageOverlap)
					scale: 1
			else
				card.animate
					x: i * (coverPage.width - pageOverlap)

	coverPage.content.on "change:x", ->
		updatePages()

	updatePages()

	return coverScreen

# Calculator Flow

showCalScreen = () ->
	currScreen = loadCalScreen()

hideCalScreen = () ->
	currScreen.destroy()

loadCalScreen = () ->
	# Data
	tableY = 582
	tableH = 384
	boxSize = 100
	dotSize = 16
	b2b = 20 #box to box gap
	d2b = 20 #dot to box gap
	d2d = 36 #dot to dot gap
	## start / end
	## b2b + 2 x d2b + 4 x d2d + boxSize + 5 x dotSize = tableH
	## others
	## 4 x d2b + 3 x d2d + boxSize + 5 x dotSize = tableH
	spots = [] # all possible box y positions
	currTableIndex = 0

	calScreen = new Layer
		width: 750
		height: 1334
		image: "images/dardBG3.png"

	calBG = new Layer
		parent: calScreen
		width: 676
		height: 1172
		x: 38
		y: 102
		image: "images/calBG.png"

	calLabel = new Layer
		parent: calScreen
		width: 480
		height: 50
		backgroundColor: 'transparent'
		x: Align.center
		y: 100
		html: 'Suggested Dose'
		style:
			"font-family": "TiemposMedium"
			"font-size": "48px"
			"text-align": "center"

	dotContainer = new Layer
		parent: calScreen
		x: 84
		width:16
		backgroundColor: 'transparent'

	for i in [0..4]
		dot = new Layer
			parent: dotContainer
			backgroundColor: '#fff'
			width: 16
			height: 16
			borderRadius: '100%'

	calActivity = new Layer
		parent: calScreen
		width: 660
		height: 100
		x: 46
		borderRadius: '50px'
		backgroundColor: '#fff'
		html: '<div class="table-item"><div class="table-description">Activity</div></div>'
		color: grayBlue
		style:
			'font-family': 'CalibreRegular'
			'font-size': '40px'
	calActivity.draggable = true
	calActivity.draggable.horizontal = false

	calActivityDot = new Layer
		parent: calActivity
		x: 30
		y: 34
		width: 32
		height: 32
		backgroundColor: neonGreen
		shadowX: 6
		shadowY: 12
		shadowBlur: 10
		borderWidth: 4
		borderColor: neonGreen
		borderRadius: '100%'
		style:
			'box-sizing': 'border-box'

	calActivityTime = new Layer
		parent: calActivity
		x: 96
		y: 40
		color: grayBlue
		backgroundColor: 'transparent'
		html: '12:30 PM'
		style:
			'font-family': 'CalibreSemiBold'
			'font-size': '30px'
			'letter-spacing': '3.2px'

	calSettingsBtn = new Layer
		parent: calScreen
		x: 620
		width: 100
		height: 100
		opacity: 0.00
		y: 70

	updateTableLayout = (y, h) ->
		tableY = y
		tableH = h
		calActivity.y = tableY + b2b
		calActivity.draggable.constraints =
			y: tableY + b2b
			height: tableH - b2b * 2
		# calculate possible y positions
		spots = []
		spots.push b2b
		d2d = (tableH - dotSize * 5 - boxSize - d2b * 4 ) / 3
		for i in [0..3]
			spots.push d2b * 2 + dotSize + (dotSize + d2d) * i
		spots.push tableH - b2b - boxSize
		dotContainer.y = tableY
		dotContainer.height = tableH

	updateD2D = ->
		if currTableIndex == 0 or currTableIndex == 5
			d2d = (tableH - dotSize * 5 - boxSize - d2b * 2 - b2b ) / 4
		else
			d2d = (tableH - dotSize * 5 - boxSize - d2b * 4 ) / 3

	updateDots = (t)->
		updateD2D()
		dotPos = []
		if currTableIndex != 0
			for i in [0..currTableIndex-1]
				dotPos.push i * (d2d + dotSize) + d2b
		if currTableIndex < 5
			for i in [4-currTableIndex..0]
				dotPos.push tableH - d2b - i * (d2d + dotSize) - dotSize
		for i in [0..4]
			dot = dotContainer.children[i]
			dot.animate
				y: dotPos[i]
				curve: 'ease-in-out'
				options:
					time: t
		return

	getClosestY = (y) ->
		min = 1000
		result = 0
		for i in [0..spots.length-1]
			one = spots[i]
			d = Math.abs(y - one)
			if d < min
				min = d
				result = i
		return result

	updateTime = () ->
		timeStr = ''
		if currTableIndex == 0
			timeStr = "12:30 PM"
		else if currTableIndex == 1
			timeStr = "12:45 PM"
		else if currTableIndex == 2
			timeStr = "1:00 PM"
		else if currTableIndex == 3
			timeStr = "1:15 PM"
		else if currTableIndex == 4
			timeStr = "1:30 PM"
		else if currTableIndex == 5
			timeStr = "1:45 PM"
		calActivityTime.html = timeStr

	snapToTable = (y) ->
		index = getClosestY(y)
		newY = spots[index] + tableY
		calActivity.animate
			y: newY
			options:
				time: 0.3
				curve: Spring(damping: 0.5)

	updateTableLayout tableY, tableH
	updateDots(0)

	calActivity.onDragStart ->
		calActivityDot.animate
			backgroundColor: '#fff'
		calActivity.animate
			scale: 1.05
			shadowColor: 'rgba(8,27,72,0.5)'
			shadowX: 0
			shadowY: 18
			shadowBlur: 66
			shadowSpread: 14

	calActivity.onDrag ->
		# update time
		index = getClosestY(calActivity.y - tableY)
		if index != currTableIndex
			currTableIndex = index
			updateTime()
			updateDots(0.3)
	calActivity.onDragEnd ->
		calActivityDot.animate
			backgroundColor: neonGreen
		calActivity.animate
			scale: 1
			shadowX: 0
			shadowY: 0
			shadowSpread: 0
			shadowBlur: 0
		snapToTable calActivity.y - tableY

	calSettingsBtn.on Events.Tap, () ->
		showSystemMenu()

	return calScreen

# Discovery Flow
discoveryCanvasP5 = null
## Data
foodData =
	title: 'Food'
	metrics: 'images/discoveryCanvasBG2.png'
	reverse: false
	curves:
		default: [
			[88, 536, 88, 536, 604, 536, 604, 536],
			[88, 536, 88, 536, 140, 420, 308, 420, 480, 420, 496, 520, 604, 536],
			[88, 536, 88, 536, 140, 336, 310, 336, 490, 336, 498, 512, 612, 536],
			[88, 536, 88, 536, 146, 280, 336, 280, 524, 280, 534, 502, 660, 536],
			[88, 536, 88, 536, 144, 254, 332, 254, 524, 254, 534, 496, 656, 536]
		]
		average: [
			[88, 536, 88, 536, 676, 536, 676, 536],
			[88, 536, 88, 536, 140, 350, 350, 350, 540, 350, 560, 490, 676, 536],
			[88, 536, 88, 536, 144, 336, 344, 336, 520, 336, 570, 510, 682, 536],
			[88, 536, 88, 536, 140, 336, 350, 336, 524, 336, 570, 504, 660, 536],
			[88, 536, 88, 536, 170, 354, 330, 354, 456, 354, 472, 488, 622, 536]
		]
	table: [
		{
			"header": {
				"title": "0-15g Portion",
				"subtitle": "1/4"
			},
			"list": [
				{
					'factor': '11g'
					'mgdl': '+20'
					'duration': '2:00'
				},
				{
					'factor': '9g'
					'mgdl': '+40'
					'duration': '1:00'
				},
				{
					'factor': '14g'
					'mgdl': '+20'
					'duration': '1:30'
				}
			]
		},
		{
			"header": {
				"title": "16-30g Portion",
				"subtitle": "2/4"
			},
			"list": [
				{
					'factor': '22g'
					'mgdl': '+30'
					'duration': '2:00'
				},
				{
					'factor': '18g'
					'mgdl': '+50'
					'duration': '1:00'
				},
				{
					'factor': '29g'
					'mgdl': '+40'
					'duration': '1:30'
				}
			]
		},
		{
			"header": {
				"title": "31-45g Portion",
				"subtitle": "3/4"
			},
			"list": [
				{
					'factor': '45g'
					'mgdl': '+50'
					'duration': '2:00'
				},
				{
					'factor': '33g'
					'mgdl': '+80'
					'duration': '1:00'
				},
				{
					'factor': '42g'
					'mgdl': '+50'
					'duration': '1:30'
				}
			]
		},
		{
			"header": {
				"title": "46-60g Portion",
				"subtitle": "4/4"
			},
			"list": [
				{
					'factor': '60g'
					'mgdl': '+80'
					'duration': '4:00'
				},
				{
					'factor': '55g'
					'mgdl': '+100'
					'duration': '3:00'
				},
				{
					'factor': '53g'
					'mgdl': '+70'
					'duration': '2:00'
				}
			]
		}
	]


activityData =
	title: 'Activity'
	metrics: 'images/discoveryCanvasBG1.png'
	reverse: true
	curves:
		default: [
			[88, 174, 88, 174, 480, 174, 480, 174],
			[88, 174, 88, 174, 124, 322, 256, 322, 388, 322, 394, 200, 480, 174],
			[88, 174, 88, 174, 120, 372, 256, 372, 384, 372, 396, 204, 480, 174],
			[88, 174, 88, 174, 138, 408, 306, 408, 482, 408, 494, 210, 602, 174],
			[88, 174, 88, 174, 138, 400, 322, 400, 512, 400, 520, 208, 636, 174]
		]
		average: [
			[88, 174, 88, 174, 480, 174, 480, 174],
			[88, 174, 88, 174, 128, 322, 270, 322, 404, 322, 430, 212, 480, 174],
			[88, 174, 88, 174, 130, 374, 270, 374, 412, 374, 436, 212, 480, 174],
			[88, 174, 88, 174, 132, 356, 288, 356, 440, 356, 454, 202, 552, 174],
			[88, 174, 88, 174, 130, 330, 270, 330, 400, 330, 416, 208, 498, 174]
		]
	table: [
		{
			"header": {
				"title": "15min Duration",
				"subtitle": "1/4"
			},
			"list": [
				{
					'factor': 'Easy'
					'mgdl': '-10'
					'duration': '1:00'
				},
				{
					'factor': 'Easy'
					'mgdl': '-20'
					'duration': '1:20'
				},
				{
					'factor': 'Easy'
					'mgdl': '-30'
					'duration': '1:40'
				},
				{
					'factor': 'Hard'
					'mgdl': '-40'
					'duration': '2:00'
				},
				{
					'factor': 'Hard'
					'mgdl': '-50'
					'duration': '2:20'
				},
				{
					'factor': 'Hard'
					'mgdl': '-60'
					'duration': '2:40'
				}
			]
		},
		{
			"header": {
				"title": "30min Duration",
				"subtitle": "2/4"
			},
			"list": [
				{
					'factor': 'Easy'
					'mgdl': '-10'
					'duration': '1:00'
				},
				{
					'factor': 'Easy'
					'mgdl': '-20'
					'duration': '1:20'
				},
				{
					'factor': 'Easy'
					'mgdl': '-30'
					'duration': '1:40'
				},
				{
					'factor': 'Hard'
					'mgdl': '-40'
					'duration': '2:00'
				},
				{
					'factor': 'Hard'
					'mgdl': '-50'
					'duration': '2:20'
				},
				{
					'factor': 'Hard'
					'mgdl': '-60'
					'duration': '2:40'
				}
			]
		},
		{
			"header": {
				"title": "45min Duration",
				"subtitle": "3/4"
			},
			"list": [
				{
					'factor': 'Easy'
					'mgdl': '-10'
					'duration': '1:00'
				},
				{
					'factor': 'Easy'
					'mgdl': '-20'
					'duration': '1:20'
				},
				{
					'factor': 'Easy'
					'mgdl': '-30'
					'duration': '1:40'
				},
				{
					'factor': 'Hard'
					'mgdl': '-40'
					'duration': '2:00'
				},
				{
					'factor': 'Hard'
					'mgdl': '-50'
					'duration': '2:20'
				},
				{
					'factor': 'Hard'
					'mgdl': '-60'
					'duration': '2:40'
				}
			]
		},
		{
			"header": {
				"title": "60min Duration",
				"subtitle": "4/4"
			},
			"list": [
				{
					'factor': 'Easy'
					'mgdl': '-10'
					'duration': '1:00'
				},
				{
					'factor': 'Easy'
					'mgdl': '-20'
					'duration': '1:20'
				},
				{
					'factor': 'Easy'
					'mgdl': '-30'
					'duration': '1:40'
				},
				{
					'factor': 'Hard'
					'mgdl': '-40'
					'duration': '2:00'
				},
				{
					'factor': 'Hard'
					'mgdl': '-50'
					'duration': '2:20'
				},
				{
					'factor': 'Hard'
					'mgdl': '-60'
					'duration': '2:40'
				}
			]
		}
	]

# Functions

addSecHeader = (title, subtitle, p, x, y) ->
	header = new Layer
		parent: p
		width: Screen.width
		height: 160
		html: '<div class="section-header"><div class="section-title">' + title + '</div><div class="section-subtitle">' + subtitle + '</div></div>'
		y: y
		x: 0
		image: "images/sectionHeader.png"
		backgroundColor: '#253E58'
	header.position = header.y
	return header

createListItem = (data, p, x, y) ->
	item = new Layer
		width: Screen.width
		height: 90
		x: x
		y: y
		parent: p
		backgroundColor: 'transparent'
		html: '<div class="section-list-item"><div class="factor">' + data.factor + '</div><div class="mgdl">' + data.mgdl + '</div><div class="duration">' + data.duration + '</div></div>'
	return item

addSecList = (data, p, x, y) ->
	list = new Layer
		x: x
		y: y
		parent: p
		width: Screen.width
		height: data.length * 90
		backgroundColor: 'transparent'
	ly = 0
	for one in data
		item = createListItem one, list, 0, ly
		ly += item.height
	return list

showDiscoveryScreen = () ->
	currScreen = loadDiscoveryScreen()

hideDiscoveryScreen = () ->
	if discoveryCanvasP5
		discoveryCanvasP5.remove()
	currScreen.destroy()

loadDiscoveryScreen = () ->

	sectionHeaders = []
	currSection = 0
	activityCurvePoints = []
	averageCurvePoints = []
	curves = []
	curveIndex = 1

	discoveryScreen = new Layer
		width: 750
		height: 1334
		image: "images/dardBG3.png"

	discoveryLabel = new Layer
		parent: discoveryScreen
		width: 480
		height: 50
		backgroundColor: 'transparent'
		x: Align.center
		y: 100
		html: 'Discovery'
		style:
			"font-family": "TiemposMedium"
			"font-size": "48px"
			"text-align": "center"

	discoveryCloseBtn = new Layer
		parent: discoveryScreen
		width: 148
		height: 150
		image: "images/coverCancelBtn.png"
		y: 64
		x: 40
		opacity: 0
	addFadeInOut discoveryCloseBtn
	discoveryCloseBtn.on Events.Tap, () ->
		scroll.hide()
		discoveryInsulinBtn.popin()
		discoveryFoodBtn.popin()
		discoveryActivityBtn.popin()
		discoveryStressBtn.popin()
		discoverySettingBtn.visible = true
		discoveryCloseBtn.popout.start()
		loadAllCurves discoveryCanvasP5

	discoverySettingBtn = new Layer
		parent: discoveryScreen
		width: 60
		height: 60
		image: "images/mainSettingBtn.png"
		x: 652
		y: 80

	discoverySettingBtn.on Events.Tap, ()->
		showSystemMenu()

	scroll = new ScrollComponent
		parent: discoveryScreen
		width: 750
		height: 519
		y: 832
		backgroundColor: '#253E58'
		contentInset:
			bottom: 60
		opacity: 0
	scroll.scrollHorizontal = false
	scroll.slideIn = new Animation scroll,
		y: 832
	scroll.show = () ->
		scroll.y = 1200
		scroll.opacity = 1
		scroll.slideIn.start()
	scroll.hide = () ->
		scroll.animate
			opacity: 0


	discoveryCanvasBG = new Layer
		parent: discoveryScreen
		width: 750
		height: 638
		y: 196
		image: "images/discoveryCanvasBG0.png"

	discoveryCanvas = new Layer
		parent: discoveryScreen
		html: '<div id="discovery_canvas"></div>'
		backgroundColor: "transparent"
		x: Align.center
		y: 192
		width: Screen.width
		height: Screen.height

	graphLabels = new Layer
		parent: discoveryScreen
		y: 300
		width: 750
		height: 520
		backgroundColor: 'transparent'
		opacity: 0
	addFadeInOut graphLabels
	labelFood = new Layer
		parent: graphLabels
		backgroundColor: 'transparent'
		html: '<div class="graph-label">FOOD</div>'
		width: 88
		height: 39
		x: 220
		y: 48
	labelStress = new Layer
		parent: graphLabels
		backgroundColor: 'transparent'
		html: '<div class="graph-label">BASAGLAR (50U)</div>'
		width: 279
		height: 24
		x: 168
		y: 376
	labelActivity = new Layer
		parent: graphLabels
		backgroundColor: 'transparent'
		html: '<div class="graph-label">ACTIVITY</div>'
		width: 139
		height: 33
		x: 372
		y: 440
	labelInsulin = new Layer
		parent: graphLabels
		backgroundColor: 'transparent'
		html: '<div class="graph-label">HUMALOG (10U)</div>'
		width: 279
		height: 24
		x: 135
		y: 473

	triggerSectionUpdated = (s) ->
		currSection = s
		curveIndex = s + 1
		curves[0].addTargetCurve activityCurvePoints[curveIndex]
		curves[0].animateTarget = true
		curves[1].addTargetCurve averageCurvePoints[curveIndex]
		curves[1].animateTarget = true

	loadAllCurves = (p5obj) ->
		# create curve from points
		discoveryCanvasBG.image = "images/discoveryCanvasBG0.png"
		curves = []
		startData = [0, 440, 0, 440, 750, 440, 750, 440]
		color =
			r: 84
			g: 238
			b: 229
		one = [0, 440, 56, 364, 76, 128, 252, 128, 480, 128, 372, 440, 750, 440]
		curve = new Curve generatePointsFromArray(startData), p5obj.drawingContext, null, null, null, null, color
		curve.addTargetCurve generatePointsFromArray(one)
		curves.push curve

		one = [0, 440, 62, 518, 64, 628, 240, 628, 476, 628, 364, 440, 750, 440]
		curve = new Curve generatePointsFromArray(startData), p5obj.drawingContext, null, null, null, null, color
		curve.addTargetCurve generatePointsFromArray(one)
		curve.reverse = true
		curves.push curve

		one = [0, 440, 204, 466, 216, 580, 436, 580, 580, 580, 622, 480, 750, 440]
		curve = new Curve generatePointsFromArray(startData), p5obj.drawingContext, null, null, null, null, color
		curve.addTargetCurve generatePointsFromArray(one)
		curve.displayShadow = true
		curve.reverse = true
		curves.push curve

		one = [0, 440, 90, 460, 104, 520, 200, 520]
		endPts = [
			{
				x: 750
				y: 520
			},
			{
				x: 750
				y: 440
			}
		]
		curve = new Curve generatePointsFromArray(startData), p5obj.drawingContext, null, endPts, null, null, color
		curve.addTargetCurve generatePointsFromArray(one)
		curve.displayShadow = true
		curve.reverse = true
		curves.push curve

		Utils.delay 0.5, () ->
			for one in curves
				one.animateTarget = true
		Utils.delay 0.7, () ->
			graphLabels.popin.start()

	loadSectionData = (data, p5obj) ->
		discoveryLabel.html = data.title
		# curves
		discoveryCanvasBG.image = data.metrics
		p5obj.reverse = data.reverse
		# create curve points
		activityCurvePoints = []
		averageCurvePoints = []
		curves = []
		curveIndex = 1
		for one in data.curves.default
			points = generatePointsFromArray one
			activityCurvePoints.push points
		for one in data.curves.average
			points = generatePointsFromArray one
			averageCurvePoints.push points
		# create curve from points
		gradient1 =
			x: 0
			y: Math.max.apply( Math, activityCurvePoints[curveIndex].map( (o)-> return o.y ))
		gradient2 =
			x: 0
			y: activityCurvePoints[curveIndex][0].y
		color =
			r: 84
			g: 238
			b: 229
		curve = new Curve activityCurvePoints[0], p5obj.drawingContext, null, null, gradient1, gradient2, color
		curve.addTargetCurve activityCurvePoints[curveIndex]
		curve.reverse = data.reverse
		curves.push curve
		color =
			r: 255
			g: 255
			b: 255
		curve = new Curve averageCurvePoints[0], p5obj.drawingContext, null, null, null, null, color
		curve.addTargetCurve averageCurvePoints[curveIndex]
		curve.dashedCurve = true
		curve.reverse = data.reverse
		curves.push curve

		# section table
		for one in scroll.content.children
			one.destroy()
		scroll.scrollY = 0
		sectionHeaders = []
		posY = 0
		currSection = 0
		for one in data.table
			headerData = one.header
			listData = one.list
			header = addSecHeader headerData.title, headerData.subtitle, scroll.content, 0, posY
			header.index = 1
			posY += header.height
			list = addSecList listData, scroll.content, 0, posY
			list.index = 0
			posY += list.height + 100
			sectionHeaders.push header

		scroll.updateContent()
		Utils.delay 0.5, () ->
			for one in curves
				one.animateTarget = true

	# For Events.Move
	scroll.onMove ->
	# 	print "Moving", scroll.scrollY
		for header in sectionHeaders
			header.y = header.position
		for index in [sectionHeaders.length-1 .. 0]
			header = sectionHeaders[index]
			if scroll.scrollY > header.position
				header.y = scroll.scrollY
				if currSection != index
					triggerSectionUpdated index
				break

	discoveryInsulinBtn = new Layer
		parent: discoveryScreen
		width: 148
		height: 194
		x: 88
		y: 1108
		image: "images/discoveryInsulinBtn.png"
	discoveryInsulinBtn.popin = () ->
		discoveryInsulinBtn.visible = true
		discoveryInsulinBtn.opacity = 0
		discoveryInsulinBtn.animate
			opacity: 1

	discoveryFoodBtn = new Layer
		parent: discoveryScreen
		width: 148
		height: 194
		x: 240
		y: 1108
		image: "images/discoveryFoodBtn.png"
	discoveryFoodBtn.popin = () ->
		discoveryFoodBtn.visible = true
		discoveryFoodBtn.opacity = 0
		discoveryFoodBtn.animate
			opacity: 1
	discoveryFoodBtn.on Events.Tap, ()->
		loadSectionData foodData, discoveryCanvasP5
		discoveryInsulinBtn.visible = false
		discoveryFoodBtn.visible = false
		discoveryActivityBtn.visible = false
		discoveryStressBtn.visible = false
		discoverySettingBtn.visible = false
		discoveryCloseBtn.popin.start()
		graphLabels.popout.start()
		scroll.show()

	discoveryActivityBtn = new Layer
		parent: discoveryScreen
		width: 148
		height: 194
		x: 386
		y: 1108
		image: "images/discoveryActivityBtn.png"
	discoveryActivityBtn.popin = () ->
		discoveryActivityBtn.visible = true
		discoveryActivityBtn.opacity = 0
		discoveryActivityBtn.animate
			opacity: 1
	discoveryActivityBtn.on Events.Tap, ()->
		loadSectionData activityData, discoveryCanvasP5
		discoveryInsulinBtn.visible = false
		discoveryFoodBtn.visible = false
		discoveryActivityBtn.visible = false
		discoveryStressBtn.visible = false
		discoverySettingBtn.visible = false
		discoveryCloseBtn.popin.start()
		graphLabels.popout.start()
		scroll.show()

	discoveryStressBtn = new Layer
		parent: discoveryScreen
		width: 148
		height: 194
		x: 544
		y: 1108
		image: "images/discoveryStressBtn.png"
	discoveryStressBtn.popin = () ->
		discoveryStressBtn.visible = true
		discoveryStressBtn.opacity = 0
		discoveryStressBtn.animate
			opacity: 1

	discoveryCanvasObj = (p)->
		p.setup = ->
			p.createCanvas(Screen.width, discoveryCanvasBG.height)
			p.frameRate = 30
		p.draw = ->
			p.clear()
			for one in curves
				if one.reverse
					one.gradientPt1 =
						x: 0
						y: Math.max.apply( Math, one.points.map( (o)-> return o.y ))
					one.gradientPt2 =
						x: 0
						y: one.points[0].y
				else
					one.gradientPt1 =
						x: 0
						y: Math.min.apply( Math, one.points.map( (o)-> return o.y ))
					one.gradientPt2 =
						x: 0
						y: one.points[0].y
				one.update()
				one.draw()

	discoveryCanvasP5 = new p5(discoveryCanvasObj, 'discovery_canvas')
	loadAllCurves discoveryCanvasP5
	return discoveryScreen


# Keyboard Flow

showKeyboard = () ->
	currScreen = loadKeyboard()

hideKeyboard = () ->
	currScreen.destroy()

loadKeyboard = () ->
	keyboardScreen = new Layer
		width: 750
		height: 1334
		image: "images/dardBG3.png"
	keyboardBGLabel = new Layer
		parent: keyboardScreen
		width: 232
		height: 262
		image: "images/keyboardBGLabel.png"
		x: 256
		y: 336
	closeBtn = new Layer
		parent: keyboardScreen
		width: 148
		height: 150
		image: "images/coverCancelBtn.png"
		y: 64
		x: 40
	closeBtn.on Events.Tap, () ->
		hideKeyboard()

	keypad = new Layer
		parent: keyboardScreen
		width: 750
		height: 432
		image: "images/keypad.png"
		y: 902
	keypad.value = ''
	bgLabel = new Layer
		parent: keyboardScreen
		backgroundColor: 'transparent'
		html: '---'
		y: 400
		x: 258
		width: 235
		height: 160
		style:
			'font-family': 'CalibreRegular'
			'font-size': '160px'
			'line-height': '160px'
			'text-align': 'center'
	key1 = new Layer
		parent: keypad
		y: 0
		width: 244
		height: 108
		opacity: 0.00
	key1.on Events.Tap, ->
		keypad.value += '1'
		keypad.value = keypad.value.slice(-3) if keypad.value.length > 3
		updateBGValue()
	key2 = new Layer
		parent: keypad
		width: 262
		height: 108
		opacity: 0.00
		x: 244
	key2.on Events.Tap, ->
		keypad.value += '2'
		keypad.value = keypad.value.slice(-3) if keypad.value.length > 3
		updateBGValue()
	key3 = new Layer
		parent: keypad
		width: 244
		height: 108
		opacity: 0.00
		x: 506
	key3.on Events.Tap, ->
		keypad.value += '3'
		keypad.value = keypad.value.slice(-3) if keypad.value.length > 3
		updateBGValue()
	key4 = new Layer
		parent: keypad
		y: 108
		width: 244
		height: 108
		opacity: 0.00
	key4.on Events.Tap, ->
		keypad.value += '4'
		keypad.value = keypad.value.slice(-3) if keypad.value.length > 3
		updateBGValue()
	key5 = new Layer
		parent: keypad
		y: 108
		width: 262
		height: 108
		opacity: 0.00
		x: 244
	key5.on Events.Tap, ->
		keypad.value += '5'
		keypad.value = keypad.value.slice(-3) if keypad.value.length > 3
		updateBGValue()
	key6 = new Layer
		parent: keypad
		y: 108
		width: 244
		height: 108
		opacity: 0.00
		x: 506
	key6.on Events.Tap, ->
		keypad.value += '6'
		keypad.value = keypad.value.slice(-3) if keypad.value.length > 3
		updateBGValue()
	key7 = new Layer
		parent: keypad
		y: 216
		width: 244
		height: 108
		opacity: 0.00
	key7.on Events.Tap, ->
		keypad.value += '7'
		keypad.value = keypad.value.slice(-3) if keypad.value.length > 3
		updateBGValue()
	key8 = new Layer
		parent: keypad
		y: 216
		width: 262
		height: 108
		opacity: 0.00
		x: 244
	key8.on Events.Tap, ->
		keypad.value += '8'
		keypad.value = keypad.value.slice(-3) if keypad.value.length > 3
		updateBGValue()
	key9 = new Layer
		parent: keypad
		y: 216
		width: 244
		height: 108
		opacity: 0.00
		x: 506
	key9.on Events.Tap, ->
		keypad.value += '9'
		keypad.value = keypad.value.slice(-3) if keypad.value.length > 3
		updateBGValue()
	key0 = new Layer
		parent: keypad
		y: 324
		width: 262
		height: 108
		opacity: 0.00
		x: 244
	key0.on Events.Tap, ->
		keypad.value += '0'
		keypad.value = keypad.value.slice(-3) if keypad.value.length > 3
		updateBGValue()
	keyCancel = new Layer
		parent: keypad
		y: 324
		width: 244
		height: 108
		opacity: 0.00
		x: 506
	keyCancel.on Events.Tap, ->
		keypad.value = keypad.value.slice(0, -1)
		updateBGValue()
	keyClose = new Layer
		parent: keypad
		y: 324
		width: 244
		height: 108
		opacity: 0.00
	keyClose.on Events.Tap, ->
		hideKeyboard()
	updateBGValue = () ->
		if keypad.value.length == 0
			bgLabel.html = '---'
		else
			bgLabel.html = keypad.value
	return keyboardScreen

# Modal & Overlay

overlayLayer = new Layer
	width: Screen.width
	height: Screen.height
	backgroundColor: "rgba(46,76,109,0.95)"
	opacity: 0
	visible: false
overlayLayer.popin = new Animation overlayLayer,
	opacity: 1
overlayLayer.popout = overlayLayer.popin.reverse()
overlayLayer.fadein = ->
	overlayLayer.visible = true
	overlayLayer.popin.start()
overlayLayer.fadeout = ->
	overlayLayer.popout.start()
overlayLayer.on Events.AnimationEnd, (animation, layer) ->
	if animation == overlayLayer.popout
		overlayLayer.visible = false
	return true

modal = new Layer
	parent: overlayLayer
	width: 646
	height: 600
	x: Align.center
	y: -700
	backgroundColor: '#54EDE5'
	shadowX: -8
	shadowY: 16
	shadowBlur: 22
	shadowColor: 'rgba(10, 60, 117, 0.3)'
	style:
		'border-bottom-left-radius': '100px'
modal.popin = new Animation modal,
	y: Align.center
	options:
		curve: Spring(damping: 0.8)
		time: 0.5
		delay: 0.3
modal.popout = new Animation modal,
	y: -700
	options:
		curve: Spring(damping: 0.8)
		time: 0.5

setModalContent = (title, text, btn) ->
	str = '<div id="modal"><h4>' + title + '</h4><p>' + text + '</p></div>'
	modal.html = str

showLoadingScreen()
# showMainScreen()
# showCoverScreen()
# showCalScreen()
# showDiscoveryScreen()
# showKeyboard()
