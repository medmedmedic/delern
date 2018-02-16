/*
 * Copyright (C) 2017 Katarina Sheremet
 * This file is part of Delern.
 *
 * Delern is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 *
 * Delern is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with  Delern.  If not, see <http://www.gnu.org/licenses/>.
 */

package org.dasfoo.delern.test;

import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.auth.GoogleOAuthAccessToken;
import com.google.firebase.database.FirebaseDatabase;
import com.google.firebase.tasks.Tasks;

import org.dasfoo.delern.models.User;
import org.junit.rules.ExternalResource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.IOException;
import java.net.URI;
import java.util.Date;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

import io.jsonwebtoken.Jwts;
import io.reactivex.plugins.RxJavaPlugins;
import uk.org.lidalia.slf4jext.Level;
import uk.org.lidalia.slf4jtest.TestLoggerFactory;

public class FirebaseServerRule extends ExternalResource {
    private static final Logger LOGGER = LoggerFactory.getLogger(FirebaseServerRule.class);

    private static final int PORT = 5533;
    private static final String HOST = "localhost";

    private String mNode;
    private String mServer;
    private String mRules;

    private FirebaseServerRunner mFirebaseServer;

    public FirebaseServerRule() {
        super();
        findDependencies(new File(System.getProperty("user.dir")));
        RxJavaPlugins.setErrorHandler(e -> LOGGER.error("Undeliverable RxJava error", e));
        TestLoggerFactory.getInstance().setPrintLevel(Level.DEBUG);
    }

    private void findDependencies(File directory) {
        for (File f : directory.listFiles()) {
            if (f.isDirectory()) {
                findDependencies(f);
            } else {
                if (f.getName().equals("firebase-server") && f.canExecute()) {
                    mServer = f.getAbsolutePath();
                }
                if (f.getName().equals("node") && f.canExecute()) {
                    mNode = f.getAbsolutePath();
                }
                if (f.getName().equals("delern-rules.json")) {
                    mRules = f.getAbsolutePath();
                }
            }
            if (mServer != null && mNode != null && mRules != null) {
                break;
            }
        }
    }

    @Override
    protected void before() throws Throwable {
        if (mNode == null || mServer == null || mRules == null) {
            throw new RuntimeException("Cannot find dependencies: node=" + mNode + ", server=" +
                    mServer + ", rules=" + mRules);
        }

        // Add setVerbose() before start() to get more logs.
        mFirebaseServer = new FirebaseServerRunner(mNode, mServer)
                .setHost(HOST)
                .setPort(String.valueOf(PORT))
                .setRules(mRules)
                .start();

        TestLoggerFactory.clear();
    }

    @Override
    protected void after() {
        try {
            for (FirebaseApp app : FirebaseApp.getApps()) {
                app.delete();
            }
        } finally {
            try {
                mFirebaseServer.stop();
            } catch (IOException e) {
                LOGGER.error("Failed to stop firebase-server", e);
            }
        }
    }

    public User signIn() throws Exception {
        String userId = UUID.randomUUID().toString();

        final String token = Jwts.builder().setSubject(userId).setIssuedAt(new Date()).compact();
        FirebaseOptions options = new FirebaseOptions.Builder()
                .setCredential(() ->
                        Tasks.forResult(new GoogleOAuthAccessToken(token,
                                System.currentTimeMillis() +
                                        TimeUnit.MILLISECONDS.convert(1, TimeUnit.DAYS)
                        )))
                .setDatabaseUrl(new URI("ws", null, HOST, PORT, null, null, null).toString())
                .build();

        User user = new User(FirebaseDatabase.getInstance(FirebaseApp.initializeApp(options,
                userId)));
        user.setKey(userId);
        user.setName("Bob " + userId);
        return user;
    }
}