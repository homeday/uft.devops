var argv = require( 'yargs' ).argv,
 	gulp = require( 'gulp' ),
 	gutil = require( 'gulp-util' ),
    ftp = require( 'vinyl-ftp' ),
    fs = require( 'fs' ),
    path = require( 'path' ),
    filefilter = '',//require( './config' ).filefilter,
    Zip = require('node-7z'),
    Q = require('q'),
    expect = require('chai').expect;


var ftpconfig = argv.ftpcfg,
    config = argv.cfg,
    baseDir = argv.basedir,		/*--basedir=[compress folder dir]*/
    destFolder = argv.destfolder;

var ftpconf = null,
    z7option = null,
    z7folders = null;


if ( config === undefined) {
    z7folders = [
                    {z7name:'DVD', folder:'/DVD/*'},
    				{z7name:'Prerequisites', folder:'/SetupBuilder/Output/UFT/Prerequisites/*'}
    			];
    z7option = {
                    v: '60m',
                    m4: '=lzma2',
                    mmt: '=16',
                    x: '@ignore.txt'
		      };
} else {
    z7folders = require( config ).z7folders;
    z7option = require( config ).z7option;
}

if ( ftpconfig === undefined) {
    ftpconf = {
        host: '16.165.216.93',
        user: 'appsadmin',
        password: 'appsadmin',
        parallel: 8,
        log: null 
    };
} else {
    ftpconf = require( ftpconfig ).ftpconf;
}

var destFolder = argv.destfolder;

if ( destFolder === undefined ) {
   destFolder = 'test'; 
}

var aryfiles = [];

function getFtpConnection() {  
    return ftp.create(ftpconf);
}


gulp.task('compress', function() {
	
	try {
    	fs.accessSync(baseDir, fs.F_OK);
	} catch (e) {
		console.log(baseDir + " is unavailable!");
		process.exit(1);
	}

	var deferred = Q.defer();
	console.log(baseDir);
    var z7 = new Zip(); 
    var aryz7 = [];
    var index = 0;
    z7folders.forEach(function( z7folder ) {
        aryz7[index++] = z7.add(z7folder.z7name, baseDir + z7folder.folder ,z7option);
        console.log(baseDir + z7folder.folder + " will be compressed to " + z7folder.z7name + ".7z!");
    });
	
    Q.all(aryz7).then(function() {
			deferred.resolve();
		}).catch(function(err) {
            console.log("compression error!!");
            process.exit(2);
		});
	return deferred.promise;
    
	/*z7.add('sample.7z', baseDir + 'b\\*', {
			v: '60m',
			m4: '=lzma2',
			mmt: '=16',
			x: '@ignore.txt'
		})
		.progress(function (files) {
			console.log('Some files are extracted: %s', files);
		})
		.then(function () {
  			console.log('finished!');
  			deferred.resolve();
		})
		.catch(function (err) {
			expect(err).to.be.an.instanceof(Error);
		});

	z7.add('sample2.7z', baseDir + 'a\\*', {
			v: '60m',
			m4: '=lzma2',
			mmt: '=16',
			x: '@ignore.txt'
		})
		.progress(function (files) {
			console.log('Some files are compressed: %s', files);
		})
		.then(function () {
  			console.log('finished!');
  			deferred.resolve();
		})
		.catch(function (err) {
			expect(err).to.be.an.instanceof(Error);
		});

	return Q.all([z7.add('sample1.7z', baseDir + '\\b\\*',z7option),
		z7.add('sample2.7z', baseDir + '\\a\\*', {
			v: '60m',
			m4: '=lzma2',
			mmt: '=16',
			x: '@ignore.txt'
		})]).progress(function (files) {
			console.log('Some files are compressed: %s', files.index);
		}).then(function() {
			deferred.resolve();
		}).catch(function(err) {
			//expect(err).to.be.an.instanceof(Error);
            console.log(err);
            
            deferred.reject();
		});
	return deferred.promise;*/
	
});



gulp.task('prefiles', ['compress'], function() {
	var files = fs.readdirSync('./');
	files.forEach(function(file) {
		if ( file.indexOf('7z') >= 0 ) {
			file = path.resolve('./', file);
			var stat = fs.statSync(file);
			if ( stat && stat.isFile()) {
				//console.log(file);
	        	aryfiles.push(file);
			}
		}
	});
    
    aryfiles.forEach(function(z7file) {
       console.log(z7file);
    });
});


gulp.task('sync', ['prefiles'], function() {
	if ( 0 == aryfiles.length ) {
		console.log("no file found!");
		process.exit(0);
	}

	var conn = getFtpConnection();

	return gulp.src( aryfiles, { buffer: false } )
		//.pipe( conn.newer( '/public_html' ) ) // only upload newer files 
		.pipe( conn.dest( destFolder ) )
		.on('error', function() {
			console.log('Synchronization failed!');
			process.exit(1);
		})
		.on('end', function() {
			console.log('Synchronization finished!');
		});
		
});


gulp.task( 'default', ['compress', 'prefiles', 'sync'], function(){
    console.log("success!!!");
});



