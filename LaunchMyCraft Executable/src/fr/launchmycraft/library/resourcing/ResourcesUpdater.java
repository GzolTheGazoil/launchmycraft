package fr.launchmycraft.library.resourcing;

import java.io.File;
import java.io.FileInputStream;
import java.util.ArrayList;
import java.util.HashMap;

import org.apache.commons.io.FileUtils;

import com.google.gson.Gson;

import fr.launchmycraft.launcher.ExecutableMain;
import fr.launchmycraft.launcher.LoggerUtils;
import fr.launchmycraft.library.GameLauncher;
import fr.launchmycraft.library.util.Util;
import fr.launchmycraft.library.util.listeners.FileEndedListener;
import fr.launchmycraft.library.util.listeners.FileProgressionListener;
import fr.launchmycraft.library.util.listeners.StateListener;
import fr.launchmycraft.library.util.network.DownloadJob;
import fr.launchmycraft.library.util.network.Downloadable;
import fr.launchmycraft.library.util.network.HTTPDownloader;
import fr.launchmycraft.library.versionning.VersionDetails;

public class ResourcesUpdater {
	
	static String createUrl(AssetObject object)
	{
		return Util.getResourcesUrl() + object.hash.substring(0, 2) + "/" + object.hash;
	}
	
	public static void updateResources(VersionDetails versionDetails, FileProgressionListener progressListener, FileEndedListener endedListener,  final StateListener stateListener) throws Exception
	{
		//Variables
		boolean forceUpdate = GameLauncher.forceUpdate;
		HashMap<String, String> launcherDetails = ExecutableMain.launcherDetails;
		
		//Les ressources
		boolean isCustomResourcesEnabled = Util.isCustomResourcesEnabled();
        boolean resUp2Date = Util.isRevisionUpToDate(isCustomResourcesEnabled, Util.getResourcesRevisionFile(), Long.parseLong(launcherDetails.get("customresourcesrevision")), true);
        
		if (!resUp2Date || forceUpdate)
		{
			File resourcesFolder = Util.getResourcesFolder();
			File customResourcesZipFile = Util.getCustomResourcesZipFile();
			
			stateListener.onStateChanged(false, "V�rification des ressources...");		
			String assetsIndex = Util.getAssetsIndex(versionDetails);
			
			//On t�l�charge le JSON si il existe pas
			File indexFile = new File(resourcesFolder, "/" + "indexes" + "/" + assetsIndex + ".json");
			if (!indexFile.exists())
			{
				indexFile.getParentFile().mkdirs();
				//Il existe pas, on le t�l�charge
				Util.writeToFile(indexFile, Util.doGET(Util.getIndexUrl(assetsIndex), null));
			}
			//On �tablit la liste des fichiers � t�l�charger
			ArrayList<Downloadable> filesToDownload = new ArrayList<>();
			ArrayList<Resoursable> filesToCheck = new ArrayList<>();
			//On lit le JSON
			AssetIndex index = new Gson().fromJson(Util.getFileContent(new FileInputStream(indexFile), false, true), AssetIndex.class);
			//On regarde si c'est legacy
			if (assetsIndex.equals("legacy"))
			{
				LoggerUtils.println("Mode \"legacy\" utilis�.");
				//C'est legacy
				for (String key : index.objects.keySet())
				{
					AssetObject object = index.objects.get(key);
					
					//C'est legacy donc le fichier en question c'est la key
					File objectFile = new File(resourcesFolder, "/" + "virtual" + "/" + "legacy" + "/" + key);
					
					//On l'ajoute au job
					//On prend l'URL du fichier
					Resoursable able = new Resoursable(object.hash, createUrl(object), objectFile);
					filesToCheck.add(able);
				}
				
			}
			else
			{
				LoggerUtils.println("Mode normal utilis�.");
				//C'est pas legacy
				for (String key : index.objects.keySet())
				{
					AssetObject object = index.objects.get(key);				
					
					File objectFile = new File(resourcesFolder, "/" + "objects" + "/" + object.hash.substring(0, 2) + "/" + object.hash);
					
					//On l'ajoute au job
					//On prend l'URL du fichier
					Resoursable able = new Resoursable(object.hash, createUrl(object), objectFile);
					filesToCheck.add(able);
				}
			}
					
			//On v�rifie tout �a
			ResourceJob hashJob = new ResourceJob(filesToCheck, forceUpdate);
			if (!hashJob.checkAll())
			{
				throw new Exception("impossible de v�rifier les ressources");
			}
						
			for (Resoursable file : hashJob.getFilesToDownload())
			{
				filesToDownload.add(new Downloadable(file.url, file.fileToCheck));
			}
			
			LoggerUtils.println(filesToDownload.size() + " fichiers �mettre �jour.");
			
			
			//On t�l�charge tout �a			
			stateListener.onStateChanged(false, "Mise �jour des ressources...");	
			
			DownloadJob downJob = new DownloadJob(filesToDownload);
			downJob.setNewFileListener(endedListener);
			
			if (!downJob.downloadAll())
			{
				throw new Exception("impossible de t�l�charger les ressources");
			}		
            
            //Custom Resources					
            if (isCustomResourcesEnabled && (!resUp2Date || forceUpdate))
            {
            	stateListener.onStateChanged(false, "Mise � jour des ressources personnalis�es...");
            	
            	//On supprime le fichier si il existe
            	if (customResourcesZipFile.exists())
                {
            		LoggerUtils.println("Suppression de l'ancienne archive...");
                    customResourcesZipFile.delete();
                }
            	
            	LoggerUtils.println("T�l�chargement de " + launcherDetails.get("customresourcesurl"));
            	HTTPDownloader downloader = new HTTPDownloader(launcherDetails.get("customresourcesurl"), customResourcesZipFile);
            	downloader.setDownloadProgressionListener(progressListener);
            	downloader.downloadFile();
            	
            	stateListener.onStateChanged(false, "Installation des ressources personnalis�es...");		
    			
    			//On regarde si un dossier mods est pr�sent
            	if (Util.getForgeModsDirectory().exists())
            	{
            		FileUtils.deleteDirectory(Util.getForgeModsDirectory());
            	}
            	
            	//On unpack l'archive
            	Util.unpackArchive(customResourcesZipFile, Util.getGameDirectory());
                LoggerUtils.println("Nettoyage...");
                customResourcesZipFile.delete();
            	
            	//On incr�mente la r�vision
            	Util.writeToFile(Util.getResourcesRevisionFile(), launcherDetails.get("customresourcesrevision"));
            }   
		}			
	}

}
