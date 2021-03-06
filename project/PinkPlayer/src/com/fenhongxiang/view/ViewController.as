//------------------------------------------------------------------------------
//
//   Copyright 2016 www.fenhongxiang.com 
//   All rights reserved. 
//   By :ljh 
//
//------------------------------------------------------------------------------

package com.fenhongxiang.view
{
	import com.fenhongxiang.HLSPlayer;
	import com.fenhongxiang.cue.CueContainer;
	import com.fenhongxiang.cue.CueUtil;
	import com.fenhongxiang.srt.SRTController;
	import com.fenhongxiang.util.HtmlUtil;
	import com.fenhongxiang.util.SkinLoader;
	import com.fenhongxiang.util.TimeUtil;
	import com.fenhongxiang.vtt.VTTControler;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.FullScreenEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.text.TextField;
	import flash.utils.Timer;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	public final  class ViewController
	{

		public function ViewController(player:HLSPlayer, skin:MovieClip)
		{
			_player = player;

			if (_player)
			{
				_player.onPlayEnd = onVideoPlayEndHandler;
				_player.onPlayStart = onVideoPlayStartHandler;
			}
			_skin = skin;

			initSkinParts();
		}

		private var _coverPath:String;
		private var _onCoverButtonCallback:Function;
		private var _pauseADClickURL:String;
		private var _pauseADImagePath:String;
		private var _player:HLSPlayer;
		private var _skin:MovieClip;
		private var _srtController:SRTController;
		private var _stage:Stage;
		private var _timer:Timer = new Timer(450);
		private var _viewLocked:Boolean = false;
		private var _vttController:VTTControler;
		private var bigPlayButton:SimpleButton;
		private var controlBar:Sprite;
		private var coverContainer:Sprite;
		private var fullscreenButtonGroup:Sprite;
		private var isFullScreen:Boolean = false;
		private var pauseADContainer:Sprite;
		private var playerContainer:Sprite;
		
		private var progressBarContainer:Sprite;
		private var progressBar:FProgressBar;
		
		private var miniProgressBarContainer:Sprite;
		private var miniProgressBar:FProgressBar;
		
		private var loadingMovie:MovieClip;

		private var replayButton:SimpleButton;
		private var srtTextField:TextField;
		private var thumbImg:Bitmap;
		private var timeClip:Sprite;
		private var toogleButton:MovieClip;
		private var tweenID:int = -1;
		private var volumeBar:MovieClip;
		private var cuePointsContainer:CueContainer;

		public function set coverPath(value:String):void
		{
			_coverPath = value;

			if (value)
			{
				loadCoverImage();
			}
		}

		public function set onCoverButtonCallback(value:Function):void
		{
			_onCoverButtonCallback = value;
		}

		public function set pauseADClickURL(value:String):void
		{
			_pauseADClickURL = value;
		}

		public function set pauseADImagePath(value:String):void
		{
			_pauseADImagePath = value;

			if (value)
			{
				loadPauseADImage();
			}
		}

		public function set srtController(value:SRTController):void
		{
			_srtController = value;
		}

		public function set stage(value:Stage):void
		{
			_stage = value;

			if (_stage)
			{
				resizeSkin(_stage.stageWidth, _stage.stageHeight, false);
				_stage.addEventListener(KeyboardEvent.KEY_DOWN, onStageKeyDownHandler, false, 0, true);
				_stage.addEventListener(FullScreenEvent.FULL_SCREEN, onStageFullScreenHandler, false, 0, true);
				_stage.addEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMoveHandler, false, 0, true);
				_stage.addEventListener(Event.RESIZE, onSWFResizeHandler, false, 0, true);
			}
		}

		public function updateVolumeView(vol:Number):void
		{
			if (volumeBar)
			{
				if (vol < 0)
				{
					vol = 0;
				}
				else if (vol > 1)
				{
					vol = 1;
				}

				volumeBar.setVolume(vol);
			}
		}

		public function set vttController(value:VTTControler):void
		{
			_vttController = value;
		}

		private function initSkinParts():void
		{
			controlBar = SkinLoader.getInstance().getSkinPart("controlBar");

			coverContainer = SkinLoader.getInstance().getSkinPart("coverContainer");
			coverContainer.visible = true;
			SimpleButton(coverContainer['bigPlayButton']).addEventListener(MouseEvent.CLICK, function onBigPlayClick(e:MouseEvent):void
			{
				if (_onCoverButtonCallback)
				{
					coverContainer.parent.removeChild(coverContainer);
					_onCoverButtonCallback();
				}
			});

			pauseADContainer = SkinLoader.getInstance().getSkinPart("pauseADContainer");
			
			if (pauseADContainer != null)
			{
				pauseADContainer.visible = false;
			}

			bigPlayButton = SkinLoader.getInstance().getSkinPart("bigPlayButton"); //大播放按钮
			
			if (bigPlayButton != null)
			{
				bigPlayButton.cacheAsBitmap = true;
				bigPlayButton.addEventListener(MouseEvent.CLICK, onBigPlayButtonClickHandler, false, 0, true);
			}

			volumeBar = SkinLoader.getInstance().getSkinPart("controlBar", 'volumeBar'); //音量按钮
			
			if (volumeBar != null)
			{
				volumeBar.addEventListener(MouseEvent.CLICK, onVolumeBarClickHandler, false, 0, true);
			}

			toogleButton = SkinLoader.getInstance().getSkinPart("controlBar", 'toogleButton'); //暂停播放
			
			if (toogleButton != null)
			{
				toogleButton.addEventListener(MouseEvent.CLICK, onToogleButtonClickHandler, false, 0, true);
			}

			replayButton = SkinLoader.getInstance().getSkinPart("controlBar", 'replayButton'); //重播
			
			if (replayButton != null)
			{
				replayButton.addEventListener(MouseEvent.CLICK, onReplayButtonClickHandler, false, 0, true);
			}

			progressBarContainer = SkinLoader.getInstance().getSkinPart("controlBar", 'progressBar'); //进度条
			
			if (progressBarContainer != null)
			{
				progressBar = new FProgressBar();
				progressBar.resize(progressBarContainer.width, progressBarContainer.height);
				progressBarContainer.addChild(progressBar);

				progressBarContainer.addEventListener(MouseEvent.CLICK, onProgressBarClickHandler, false, 0, true);
				progressBarContainer.addEventListener(MouseEvent.MOUSE_MOVE, onProgressBarMoveHandler);
				
				cuePointsContainer = new CueContainer();
				cuePointsContainer.resize(progressBar.width, progressBar.height);
				cuePointsContainer.data = CueUtil.jsonToVector(CueUtil.testJson);;
				cuePointsContainer.y = 0;
				progressBarContainer.addChildAt(cuePointsContainer, progressBarContainer.numChildren);
			}
			
			loadingMovie = SkinLoader.getInstance().getSkinPart("controlBar", 'loadingMc'); //加载动画
			
			if (loadingMovie != null)
			{
				loadingMovie.visible = false;
			}
			
			miniProgressBarContainer = SkinLoader.getInstance().getSkinPart("miniProgressBar"); //迷你进度条
			
			if (miniProgressBarContainer != null)
			{
				miniProgressBar = new FProgressBar();
				miniProgressBar.resize(miniProgressBarContainer.width, miniProgressBarContainer.height);
				miniProgressBar.backgroundAlpha = 0.3;
				
				miniProgressBarContainer.addChild(miniProgressBar);
				miniProgressBarContainer.visible = false;
			}

			fullscreenButtonGroup = SkinLoader.getInstance().getSkinPart("controlBar", 'fullscreenButtonGroup'); //全屏按钮组
			
			if (fullscreenButtonGroup)
			{
				fullscreenButtonGroup.addEventListener(MouseEvent.CLICK, toggleFullScreen, false, 0, true);
			}

			timeClip = SkinLoader.getInstance().getSkinPart("controlBar", 'timeClip'); //时间显示

			var thumbContainer:MovieClip = SkinLoader.getInstance().getSkinPart("controlBar", 'thumbContainer');
			
			if (thumbContainer != null)
			{
				thumbContainer.mouseChildren = false;
				thumbContainer.mouseEnabled = false;
				thumbImg = new Bitmap(new BitmapData(100, 60));
				thumbImg.x = -50;
				thumbImg.y = -30;
				thumbContainer.addChild(thumbImg);
			}

			srtTextField = SkinLoader.getInstance().getSkinPart("srtTextField");

			playerContainer = SkinLoader.getInstance().getSkinPart("videoContainer");
			
			if (playerContainer != null)
			{
				playerContainer.doubleClickEnabled = true;
				playerContainer.mouseChildren = false;
				playerContainer.addEventListener(MouseEvent.DOUBLE_CLICK, onStageDoubleClickHandler, false, 0, true);
			}

			if (_player != null)
			{
				playerContainer.addChild(_player);
				_timer.addEventListener(TimerEvent.TIMER, updateView);
				_timer.reset();
				_timer.start();
				_player.volume = volumeBar.getVolume();
			}

			if (_stage != null)
			{
				resizeSkin(_stage.stageWidth, _stage.stageHeight, false);
			}
		}

		private function loadCoverImage():void
		{
			if (coverContainer && _coverPath)
			{
				var coverLdr:CoverLoader = new CoverLoader(coverContainer.width, coverContainer.height);
				coverLdr.load(_coverPath);
				coverContainer['imageContainer'].mouseEnabled = false;
				coverContainer['imageContainer'].addChild(coverLdr);
			}
		}

		private function loadPauseADImage():void
		{
			if (pauseADContainer && _pauseADImagePath)
			{
				var adLdr:CoverLoader = new CoverLoader(pauseADContainer.width, pauseADContainer.height);
				adLdr.load(_pauseADImagePath);
				adLdr.buttonMode = true;
				adLdr.useHandCursor = true;
				adLdr.addEventListener(MouseEvent.CLICK, function onADClickHandler(e:MouseEvent):void
				{
					onPauseADClickHandler(e);
				});

				pauseADContainer['adImageContainer'].mouseEnabled = false;
				pauseADContainer['adImageContainer'].addChild(adLdr);

				SimpleButton(pauseADContainer['closeButton']).addEventListener(MouseEvent.CLICK, function onADCloseButtonClick(e:MouseEvent):void
				{
					pauseADContainer.visible = false;
				});
			}
		}

		private function onBigPlayButtonClickHandler(e:MouseEvent):void
		{
			if (_player)
			{
				if (_player.stoped)
				{
					_player.play();
				}
				else
				{
					_player.play(_player.time);
				}
			}
		}
		
		private function onSWFResizeHandler(e:Event):void
		{
			if (_stage)
			{
				resizeSkin(_stage.stageWidth, _stage.stageHeight);
			}
		}

		private function onPauseADClickHandler(e:MouseEvent):void
		{
			if (_pauseADClickURL)
			{
				HtmlUtil.gotoURL(_pauseADClickURL);
			}
		}

		private function onProgressBarClickHandler(e:MouseEvent):void
		{
			var playedProgress:Number = e.currentTarget.mouseX / progressBar.width;
			_viewLocked = true;

			if (_player)
			{
				_player.seek(playedProgress, true);
				_viewLocked = false;
			}
		}

		private function onProgressBarMoveHandler(e:MouseEvent):void
		{
			if (_player)
			{
				var timePos:Number = e.currentTarget.mouseX / progressBar.width * _player.duration;

				if (_vttController)
				{
					_vttController.renderImage(timePos, thumbImg.bitmapData);
				}
				
				if (timeClip)
				{
					timeClip['timeLb']['text'] = TimeUtil.getTimeString(timePos);
				}
				
				
				if (cuePointsContainer != null)
				{
					thumbImg.visible = !cuePointsContainer.tipVisible;
					
					if (timeClip != null)
					{
						timeClip.visible = !cuePointsContainer.tipVisible;
					}
				}
			}
		}

		private function onReplayButtonClickHandler(e:MouseEvent):void
		{
			if (_player)
			{
				_player.play();
			}
		}

		private function onStageDoubleClickHandler(e:MouseEvent):void
		{
			toggleFullScreen();
		}

		private function onStageFullScreenHandler(e:FullScreenEvent):void
		{
			isFullScreen = e.fullScreen;

			if (e.fullScreen)
			{
				if (controlBar && _stage)
				{
					resizeSkin(_stage.fullScreenWidth, _stage.fullScreenHeight, true);
				}
			}
			else
			{
				if (controlBar && _stage)
				{
					resizeSkin(_stage.stageWidth, _stage.stageHeight, false);
				}
			}
		}

		private function onStageKeyDownHandler(e:KeyboardEvent):void
		{
			if (_player == null)
			{
				return;
			}
			else
			{
				if (e.keyCode == 39)//右箭头
				{
					_player.step(stepGap);
				}
				else if (e.keyCode == 37)//左箭头
				{
					_player.step(-stepGap);
				}
				else if (e.keyCode == 38)//上箭头
				{
					var upVol:Number = volumeBar.getVolume() + 0.1;
					_player.volume = upVol;
					updateVolumeView(upVol)
				}
				else if (e.keyCode == 40)//下箭头
				{ 
					var downVol:Number = volumeBar.getVolume() - 0.1;
					
					_player.volume = downVol;
					updateVolumeView(downVol)
				}
				else if (e.keyCode == 32)//空格键: 暂停切换
				{ 
					_player.togglePause();
				}
			}
		}

		private function onStageMouseMoveHandler(e:MouseEvent):void
		{
			if (tweenID != -1)
			{
				clearTimeout(tweenID);
			}

			if (controlBar)
			{
				controlBar.visible = true;
			}

			if (miniProgressBarContainer)
			{
				miniProgressBarContainer.visible = false;
			}

			tweenID = setTimeout(toogleMiniBar, 6000);
		}

		private function onToogleButtonClickHandler(e:MouseEvent):void
		{
			if (_player)
			{
				_player.togglePause();

				if (pauseADContainer && _pauseADImagePath)
				{
					pauseADContainer.visible = !_player.isPlaying;
				}
			}
		}

		private function onVideoPlayEndHandler():void
		{
			if (replayButton)
			{
				replayButton.visible = true;
			}

			if (toogleButton)
			{
				toogleButton.visible = false;
			}
		}

		private function onVideoPlayStartHandler():void
		{
			if (replayButton)
			{
				replayButton.visible = false;
			}

			if (toogleButton)
			{
				toogleButton.visible = true;
			}
		}

		private function onVolumeBarClickHandler(e:MouseEvent):void
		{
			if (_player)
			{
				_player.volume = volumeBar.getVolume();
			}
		}

		/**
		 *
		 * @param newWidth 新宽度
		 * @param newHeight 新高度
		 * @param isFull 是否全屏状态 （控制全屏按钮状态显示）
		 *
		 */
		private function resizeSkin(newWidth:Number, newHeight:Number, isFull:Boolean = false):void
		{
			var defaultBarWidth:Number = controlBar.width;

			if (coverContainer)
			{
				var imageContainer:MovieClip = coverContainer['imageContainer'];
				if (imageContainer)
				{
					imageContainer.width = newWidth;
					imageContainer.height = newHeight;
				}

				var bigPlayBtn:SimpleButton = coverContainer['bigPlayButton'];
				if (bigPlayBtn)
				{
					bigPlayBtn.x = newWidth / 2;
					bigPlayBtn.y = newHeight / 2;
				}
			}

			if (bigPlayButton)
			{
				bigPlayButton.x = newWidth / 2;
				bigPlayButton.y = newHeight / 2;
			}

			if (pauseADContainer)
			{
				if (newWidth < pauseADContainer.width)
				{
					var closeBtn:SimpleButton = pauseADContainer['closeButton'];
					if (closeBtn)
					{
						closeBtn.x = newWidth - closeBtn.width - 20;
					}

					var pauseImageContainer:MovieClip = pauseADContainer["adImageContainer"];

					if (pauseImageContainer)
					{
						pauseImageContainer.width = newWidth - 20;
					}
				}

				pauseADContainer.x = (newWidth - pauseADContainer.width) / 2;
				pauseADContainer.y = (newHeight - pauseADContainer.height) / 2;
			}

			if (controlBar['background'])
			{
				defaultBarWidth = controlBar['background'].width;
			}

			if (SkinLoader.getInstance().getSkinPart("logo"))
			{
				SkinLoader.getInstance().getSkinPart("logo").x = newWidth - (defaultBarWidth - SkinLoader.getInstance().getSkinPart("logo").x);
			}

			if (controlBar)
			{
				controlBar.y = newHeight - 45;
			}

			if (volumeBar)
			{
				volumeBar.x = newWidth - (defaultBarWidth - volumeBar.x)
			}

			if (progressBarContainer)
			{
				for (var i:int = 0; i < progressBarContainer.numChildren; i++)
				{
					progressBarContainer.getChildAt(i).width = newWidth - progressBarContainer.x - 210;
				}
			}

			if (miniProgressBarContainer)
			{
				miniProgressBarContainer.y = newHeight - miniProgressBarContainer.height;
				miniProgressBarContainer.x = 0;

				for (var j:int = 0; j < miniProgressBarContainer.numChildren; j++)
				{
					miniProgressBarContainer.getChildAt(j).width = newWidth;
				}
			}

			if (controlBar['totalTime'])
			{
				controlBar['totalTime'].x = newWidth - (defaultBarWidth - controlBar['totalTime'].x)
			}

			if (controlBar['fullscreenButtonGroup'])
			{
				controlBar['fullscreenButtonGroup'].x = newWidth - (defaultBarWidth - controlBar['fullscreenButtonGroup'].x);

				if (controlBar['fullscreenButtonGroup']['inFullBtn'])
				{
					controlBar['fullscreenButtonGroup']['inFullBtn'].visible = !isFull;
				}

				if (controlBar['fullscreenButtonGroup']['quitFullBtn'])
				{
					controlBar['fullscreenButtonGroup']['quitFullBtn'].visible = isFull;
				}
			}

			if (controlBar['currentTime'])
			{
				controlBar['currentTime'].x = newWidth - (defaultBarWidth - controlBar['currentTime'].x)
			}

			if (controlBar['timeSpacer'])
			{
				controlBar['timeSpacer'].x = newWidth - (defaultBarWidth - controlBar['timeSpacer'].x)
			}

			if (controlBar['background'])
			{
				controlBar['background'].width = newWidth;
			}

			if (_player)
			{
				_player.resize(newWidth, newHeight);
			}

			if (srtTextField)
			{
				srtTextField.width = newWidth;
				srtTextField.y = newHeight - (isFull ? 200 : 40);
			}
			
		}

		private function get stepGap():Number
		{
			return Math.max(3.0, 0.01 * _player.duration);
		}

		private function toggleFullScreen(e:MouseEvent = null):void
		{
			if (_stage)
			{
				if (_stage.displayState == StageDisplayState.FULL_SCREEN)
				{
					_stage.scaleMode = StageScaleMode.NO_SCALE;
					_stage.align = StageAlign.TOP_LEFT;
					_stage.displayState = StageDisplayState.NORMAL;
				}
				else
				{
					_stage.scaleMode = StageScaleMode.NO_SCALE;
					_stage.align = StageAlign.TOP_LEFT;
					_stage.displayState = StageDisplayState.FULL_SCREEN;
				}
			}
		}

		private function toogleMiniBar():void
		{
			if (miniProgressBarContainer)
			{
				miniProgressBarContainer.visible = !miniProgressBarContainer.visible;
			}

			if (controlBar)
			{
				controlBar.visible = !controlBar.visible;
			}
		}

		private function updateView(e:TimerEvent):void
		{
			if (_player)
			{
				if (_srtController && srtTextField)
				{
					if (isFullScreen)
					{
						_srtController.renderSRT(_player.time, srtTextField, "#FFFFFF", 30);
					}
					else
					{
						_srtController.renderSRT(_player.time, srtTextField, "#FFFFFF", 14);
					}
				}

				if (progressBar)
				{
					progressBar.updateView(_player.loadedPercent, _player.playedPercent);
				}

				if (miniProgressBar)
				{
					miniProgressBar.updateView(_player.loadedPercent, _player.playedPercent);
				}
				
				if (loadingMovie)
				{
					loadingMovie.visible = _player.isBuffering;
				}

				if (bigPlayButton)
				{
					bigPlayButton.visible = !_player.isPlaying;
				}

				if (controlBar)
				{
					controlBar['currentTime'].text = TimeUtil.getTimeString(_player.time);
					controlBar['totalTime'].text = TimeUtil.getTimeString(_player.duration);
				}

				if (_player.isPlaying)
				{
					toogleButton.visible = true;
					replayButton.visible = false;
					toogleButton.setButtonState("pause");
				}
				else
				{
					if (_player.stoped)
					{
						toogleButton.visible = false;
						replayButton.visible = true;
					}
					else
					{
						toogleButton.visible = true;
						toogleButton.setButtonState("play");
					}
				}
			}
		}
	}
}
