import os
import csv
import sys
from datetime import datetime
import pandas as pd
import matplotlib.pyplot as plt

class GitLogAnalyzer:
    def __init__(self, log_dir):
        self.log_dir = log_dir
        self.date = datetime.now().strftime("%Y%m%d")
        self.output_dir = f"Commit Logs/{self.date}/Reports"
        os.makedirs(self.output_dir, exist_ok=True)

    def parse_commit_history(self):
        """Parse the commit history CSV file"""
        cols = ['hash', 'author', 'email', 'date', 'message']
        commits_df = pd.read_csv(f"{self.log_dir}/commit_history.csv",
                               names=cols, usecols=cols)
        commits_df['date'] = pd.to_datetime(commits_df.date, format="%a %b %d %H:%M:%S %Y %z", utc=True)
        return commits_df

    def analyze_commit_patterns(self, commits_df):
        """Analyze commit patterns over time"""
        # Commits per day
        daily_commits = commits_df.groupby(commits_df['date'].dt.date).size()
        
        # Plot commit frequency
        plt.figure(figsize=(15, 7))
        daily_commits.plot(kind='line')
        plt.title('Commit Frequency Over Time')
        plt.savefig(f"{self.output_dir}/commit_frequency.png")
        plt.close()

        # Save statistics
        stats = {
            'total_commits': len(commits_df),
            'unique_authors': commits_df['author'].nunique(),
            'commit_period': f"{commits_df['date'].min()} to {commits_df['date'].max()}",
            'avg_commits_per_day': daily_commits.mean()
        }
        
        with open(f"{self.output_dir}/commit_statistics.csv", 'w') as f:
            writer = csv.writer(f)
            for key, value in stats.items():
                writer.writerow([key, value])

    def analyze_author_contributions(self):
        """Analyze developer contributions"""
        with open(f"{self.log_dir}/author_commit_counts.txt") as f:
            author_data = [line.strip().split('\t') for line in f]
        
        authors_df = pd.DataFrame(author_data, columns=['commits', 'author'])
        authors_df['commits'] = authors_df['commits'].astype(int)
        
        # Plot author contributions
        plt.figure(figsize=(15, 7))
        authors_df.plot(kind='bar', x='author', y='commits')
        plt.title('Commits by Author')
        plt.xticks(rotation=90)
        plt.tight_layout()
        plt.savefig(f"{self.output_dir}/author_contributions.png")
        plt.close()

    def analyze_merge_patterns(self):
        """Analyze merge patterns"""
        cols = ['hash', 'author', 'email', 'date', 'message']
        merges_df = pd.read_csv(f"{self.log_dir}/merge_history.csv",
                               names=cols, usecols=cols)
        merges_df['date'] = pd.to_datetime(merges_df.date, format="%a %b %d %H:%M:%S %Y %z", utc=True)
        
        # Merge frequency over time
        merge_frequency = merges_df.groupby(merges_df['date'].dt.date).size()
        
        plt.figure(figsize=(15, 7))
        merge_frequency.plot(kind='line')
        plt.title('Merge Frequency Over Time')
        plt.savefig(f"{self.output_dir}/merge_frequency.png")
        plt.close()

    def generate_report(self):
        """Generate analysis report"""
        commits_df = self.parse_commit_history()
        self.analyze_commit_patterns(commits_df)
        self.analyze_author_contributions()
        self.analyze_merge_patterns()
        
        # Generate summary report
        with open(f"{self.output_dir}/analysis_report.md", 'w') as f:
            f.write("# Git Repository Analysis Report\n\n")
            f.write(f"Analysis Date: {self.date}\n\n")
            
            f.write("## Key Findings\n\n")
            f.write("### Commit Statistics\n")
            stats_df = pd.read_csv(f"{self.output_dir}/commit_statistics.csv", header=None)
            for _, row in stats_df.iterrows():
                f.write(f"- {row[0]}: {row[1]}\n")
            
            f.write("\n### Visualizations\n")
            f.write("- Commit frequency over time (see commit_frequency.png)\n")
            f.write("- Author contributions (see author_contributions.png)\n")
            f.write("- Merge patterns (see merge_frequency.png)\n")

if __name__ == "__main__":
    commit_logs_dir = sys.argv[1]
    analyzer = GitLogAnalyzer(commit_logs_dir)
    analyzer.generate_report()