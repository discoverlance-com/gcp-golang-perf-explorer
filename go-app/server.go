package main

import (
	"context"
	"fmt"
	"html/template"
	"log/slog"
	"net/http"
	"os"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/gorilla/mux"
	"go.opentelemetry.io/contrib/instrumentation/github.com/gorilla/mux/otelmux"
	"google.golang.org/api/iterator"
)

var firestoreClient *firestore.Client

// Task represents a task in Firestore
type Task struct {
	ID        string    `firestore:"-"`
	Title     string    `firestore:"title"`
	CreatedAt time.Time `firestore:"created_at"`
}

func initFirestore(ctx context.Context) error {
	projectID := os.Getenv("GOOGLE_CLOUD_PROJECT")
	if projectID == "" {
		// Fallback detection if needed, or error.
	}

	databaseID := os.Getenv("DATABASE_ID")
	if databaseID == "" {
		databaseID = "(default)"
	}

	var err error

	firestoreClient, err = firestore.NewClientWithDatabase(ctx, projectID, databaseID)
	if err != nil {
		return fmt.Errorf("failed to create firestore client: %w", err)
	}
	return nil
}

func runServer() error {
	ctx := context.Background()
	if err := initFirestore(ctx); err != nil {
		return err
	}
	defer firestoreClient.Close()

	r := mux.NewRouter()
	r.Use(otelmux.Middleware("go-task-app"))

	// Custom Middleware for Timing
	r.Use(timingMiddleware)

	r.HandleFunc("/", indexHandler).Methods("GET")
	r.HandleFunc("/ping", pingHandler).Methods("GET")
	r.HandleFunc("/create", createFormHandler).Methods("GET")
	r.HandleFunc("/create", createTaskHandler).Methods("POST")
	r.HandleFunc("/delete/{id}", deleteTaskHandler).Methods("POST")

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	slog.InfoContext(ctx, "listening on port "+port)
	return http.ListenAndServe(":"+port, r)
}

func timingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		startTime := time.Now()
		// We need to pass startTime to the handlers
		ctx := context.WithValue(r.Context(), "startTime", startTime)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func getDuration(ctx context.Context) int64 {
	start, ok := ctx.Value("startTime").(time.Time)
	if !ok {
		return 0
	}
	return time.Since(start).Milliseconds()
}

func indexHandler(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	iter := firestoreClient.Collection("tasks").OrderBy("created_at", firestore.Desc).Documents(ctx)

	var tasks []Task
	for {
		doc, err := iter.Next()
		if err == iterator.Done {
			break
		}
		if err != nil {
			slog.ErrorContext(ctx, "failed to iterate tasks", slog.Any("error", err))
			http.Error(w, "Internal Server Error", http.StatusInternalServerError)
			return
		}
		var t Task
		if err := doc.DataTo(&t); err != nil {
			slog.ErrorContext(ctx, "failed to parse task", slog.Any("error", err))
			continue
		}
		t.ID = doc.Ref.ID
		tasks = append(tasks, t)
	}

	duration := getDuration(ctx)

	tmpl, err := template.ParseFiles("templates/index.html")
	if err != nil {
		slog.ErrorContext(ctx, "failed to parse template", slog.Any("error", err))
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		return
	}

	data := struct {
		Tasks    []Task
		Duration int64
	}{
		Tasks:    tasks,
		Duration: duration,
	}

	if err := tmpl.Execute(w, data); err != nil {
		slog.ErrorContext(ctx, "failed to execute template", slog.Any("error", err))
	}
}

func createFormHandler(w http.ResponseWriter, r *http.Request) {
	duration := getDuration(r.Context())
	data := struct {
		Duration int64
	}{
		Duration: duration,
	}

	tmpl, err := template.ParseFiles("templates/create.html")
	if err != nil {
		slog.ErrorContext(r.Context(), "failed to parse template", slog.Any("error", err))
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		return
	}
	tmpl.Execute(w, data)
}

func createTaskHandler(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	title := r.FormValue("title")
	if title != "" {
		_, _, err := firestoreClient.Collection("tasks").Add(ctx, map[string]any{
			"title":      title,
			"created_at": time.Now(),
		})
		if err != nil {
			slog.ErrorContext(ctx, "failed to create task", slog.Any("error", err))
			http.Error(w, "Internal Server Error", http.StatusInternalServerError)
			return
		}
		slog.InfoContext(ctx, "task created", slog.String("title", title))
	}
	http.Redirect(w, r, "/", http.StatusSeeOther)
}

func deleteTaskHandler(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	vars := mux.Vars(r)
	id := vars["id"]

	if id != "" {
		_, err := firestoreClient.Collection("tasks").Doc(id).Delete(ctx)
		if err != nil {
			slog.ErrorContext(ctx, "failed to delete task", slog.Any("error", err))
			http.Error(w, "Internal Server Error", http.StatusInternalServerError)
			return
		}
		slog.InfoContext(ctx, "task deleted", slog.String("taskId", id))
	}
	http.Redirect(w, r, "/", http.StatusSeeOther)
}

func pingHandler(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("I am alive!"))
}
