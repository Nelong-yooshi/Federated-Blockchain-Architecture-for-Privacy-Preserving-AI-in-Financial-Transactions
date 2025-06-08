package logger

import (
	"io"
	"os"
	"github.com/sirupsen/logrus"
)

var Log *logrus.Logger

func InitLogger(isProd bool) {
	Log = logrus.New()

	if isProd {
		Log.SetFormatter(&logrus.JSONFormatter{})
	} else {
		Log.SetFormatter(&logrus.TextFormatter{
			FullTimestamp: true,
			ForceColors: true,
		})
	}

	// Open or Create log file
	file, err := os.OpenFile("app.log", os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		Log.Warn("Cannot open log file, only use stdout")
		Log.SetOutput(os.Stdout)
		return
	}

	colorFormatter := &logrus.TextFormatter{
		FullTimestamp: true,
		ForceColors: true,
	}

	plainFormatter := &logrus.TextFormatter{
		FullTimestamp: true,
		DisableColors: true,
	}
	
	stdoutLogger := logrus.New()
	stdoutLogger.SetOutput(os.Stdout)
	stdoutLogger.SetFormatter(colorFormatter)
	stdoutLogger.SetLevel(logrus.DebugLevel)

	fileLogger := logrus.New()
	fileLogger.SetOutput(file)
	fileLogger.SetFormatter(plainFormatter)
	fileLogger.SetLevel(logrus.DebugLevel)

	Log = logrus.New()
	Log.SetOutput(io.MultiWriter(stdoutLogger.Writer(), fileLogger.Writer()))
	Log.SetFormatter(&logrus.TextFormatter{DisableTimestamp: true, DisableLevelTruncation: true})
	Log.SetLevel(logrus.DebugLevel)
}